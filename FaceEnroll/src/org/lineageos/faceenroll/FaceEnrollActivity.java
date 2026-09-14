/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.faceenroll;

import android.app.Activity;
import android.content.Intent;
import android.hardware.face.FaceEnrollOptions;
import android.hardware.face.FaceManager;
import android.os.Bundle;
import android.os.CancellationSignal;
import android.os.UserHandle;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.WindowManager;
import android.widget.TextView;

import java.util.ArrayList;

/**
 * Face enrollment for a HAL that opens the camera itself and renders the preview into a
 * surface it is handed.
 *
 * Settings reaches this in place of its own FaceEnrollEnrolling through
 * config_face_enroll, which is how that screen is meant to be replaced, so none of AOSP
 * needs patching. The extras and result codes below are its side of that contract.
 */
public class FaceEnrollActivity extends Activity {

    private static final String TAG = "FaceEnroll";

    // Settings puts these in the intent. Literals rather than constants because the classes
    // that declare them are internal to Settings.
    private static final String EXTRA_KEY_CHALLENGE_TOKEN = "hw_auth_token";
    private static final String EXTRA_KEY_SENSOR_ID = "sensor_id";
    private static final String EXTRA_KEY_REQUIRE_DIVERSITY = "accessibility_diversity";
    private static final String EXTRA_KEY_REQUIRE_VISION = "accessibility_vision";
    private static final String EXTRA_FINISHED_ENROLL_FACE = "finished_enrolling_face";
    private static final String EXTRA_ENROLL_REASON = "android.provider.extra.ENROLL_REASON";

    // Settings' BiometricEnrollBase result codes.
    private static final int RESULT_FINISHED = RESULT_FIRST_USER;
    private static final int RESULT_TIMEOUT = RESULT_FIRST_USER + 2;

    // BiometricFaceConstants, which is hidden and not worth a dependency for a few ints.
    private static final int FEATURE_REQUIRE_ATTENTION = 1;
    private static final int FEATURE_REQUIRE_REQUIRE_DIVERSITY = 2;
    private static final int FACE_ERROR_TIMEOUT = 3;
    private static final int FACE_ERROR_CANCELED = 5;

    private FaceManager mFaceManager;
    private CancellationSignal mCancel;
    private TextView mStatus;
    private CircleMaskView mMask;
    private int mTotalSteps;

    private byte[] mToken;
    private int mUserId;
    private int[] mDisabledFeatures;
    private boolean mEnrolling;
    private boolean mFinished;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Enrollment takes a while and the user is looking at the screen rather than
        // touching it.
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        setContentView(R.layout.face_enroll);
        mStatus = findViewById(R.id.status);
        mMask = findViewById(R.id.mask);

        final Intent intent = getIntent();
        mToken = intent.getByteArrayExtra(EXTRA_KEY_CHALLENGE_TOKEN);
        mUserId = intent.getIntExtra(Intent.EXTRA_USER_ID, UserHandle.myUserId());

        final ArrayList<Integer> disabled = new ArrayList<>();
        if (!intent.getBooleanExtra(EXTRA_KEY_REQUIRE_DIVERSITY, true)) {
            disabled.add(FEATURE_REQUIRE_REQUIRE_DIVERSITY);
        }
        if (!intent.getBooleanExtra(EXTRA_KEY_REQUIRE_VISION, true)) {
            disabled.add(FEATURE_REQUIRE_ATTENTION);
        }
        mDisabledFeatures = new int[disabled.size()];
        for (int i = 0; i < disabled.size(); i++) {
            mDisabledFeatures[i] = disabled.get(i);
        }

        mFaceManager = getSystemService(FaceManager.class);
        if (mFaceManager == null || mToken == null) {
            Log.e(TAG, "No face manager or no auth token, nothing to enroll with");
            finishWith(RESULT_CANCELED, false);
            return;
        }

        final SurfaceView preview = findViewById(R.id.preview);
        // Deliberately no setFixedSize. The HAL sets the buffer geometry on the native
        // window itself, and forcing a size here changes the stream configuration it ends
        // up with: the camera pipeline then cannot build its usual preview graph and the
        // frames arrive unprocessed. Stock hands over a plain square SurfaceView the same
        // way.
        preview.getHolder().addCallback(new SurfaceHolder.Callback() {
            @Override
            public void surfaceCreated(SurfaceHolder holder) {
                startEnrollment(holder);
            }

            @Override
            public void surfaceChanged(SurfaceHolder holder, int f, int w, int h) {
            }

            @Override
            public void surfaceDestroyed(SurfaceHolder holder) {
                // The HAL is drawing into this surface; once it is gone it has nowhere to
                // put the preview, so stop rather than leave it running blind.
                if (mCancel != null && !mCancel.isCanceled()) {
                    mCancel.cancel();
                }
            }
        });
    }

    private void startEnrollment(SurfaceHolder holder) {
        if (mEnrolling || mFinished) {
            return;
        }
        mEnrolling = true;
        mCancel = new CancellationSignal();
        final FaceEnrollOptions options = new FaceEnrollOptions.Builder()
                .setEnrollReason(getIntent().getIntExtra(EXTRA_ENROLL_REASON,
                        FaceEnrollOptions.ENROLL_REASON_UNKNOWN))
                .build();
        mFaceManager.enroll(mUserId, mToken, mCancel, mEnrollmentCallback, mDisabledFeatures,
                holder.getSurface(), false /* debugConsent */, options);
    }

    private final FaceManager.EnrollmentCallback mEnrollmentCallback =
            new FaceManager.EnrollmentCallback() {
        @Override
        public void onEnrollmentProgress(int remaining) {
            if (mTotalSteps == 0) {
                // The HAL only says how many are left, so the first callback is the total.
                mTotalSteps = remaining + 1;
            }
            mMask.setFraction(1f - (float) remaining / mTotalSteps);
            if (remaining > 0) {
                mStatus.setText(getString(R.string.enroll_remaining, remaining));
                return;
            }
            mStatus.setText(R.string.enroll_done);
            finishWith(RESULT_FINISHED, true);
        }

        @Override
        public void onEnrollmentHelp(int helpMsgId, CharSequence helpString) {
            if (helpString != null) {
                mStatus.setText(helpString);
            }
        }

        @Override
        public void onEnrollmentError(int errMsgId, CharSequence errString) {
            Log.e(TAG, "Enrollment error " + errMsgId + ": " + errString);
            if (errMsgId == FACE_ERROR_CANCELED) {
                // Our own cancel, on the way out. Nothing to report.
                finishWith(RESULT_CANCELED, false);
                return;
            }
            if (errString != null) {
                mStatus.setText(errString);
            }
            // Only a real timeout ends the whole flow. Anything else returns to the page
            // that sent us here, so it can be tried again.
            finishWith(errMsgId == FACE_ERROR_TIMEOUT ? RESULT_TIMEOUT : RESULT_CANCELED,
                    false);
        }
    };

    private void finishWith(int resultCode, boolean enrolled) {
        if (mFinished) {
            return;
        }
        mFinished = true;
        final Intent data = new Intent();
        data.putExtra(EXTRA_FINISHED_ENROLL_FACE, enrolled);
        setResult(resultCode, data);
        finish();
    }

    @Override
    protected void onDestroy() {
        if (mCancel != null && !mCancel.isCanceled() && !mFinished) {
            mCancel.cancel();
        }
        super.onDestroy();
    }
}
