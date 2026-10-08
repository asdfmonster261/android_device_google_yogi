/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.faceenroll;

import android.app.Activity;
import android.content.Intent;
import android.hardware.face.FaceEnrollCell;
import android.hardware.face.FaceEnrollOptions;
import android.hardware.face.FaceManager;
import android.os.Bundle;
import android.os.CancellationSignal;
import android.os.SystemClock;
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
    private static final int FACE_ACQUIRED_VENDOR_BASE = 1000;

    // FaceEnrollStages, likewise.
    private static final int STAGE_HOLD_STILL_IN_CENTER = 3;

    // Enrollment wants the head straight on and tilted both ways. The HAL reports which
    // tilt a frame caught as a vendor code, 101 to 120 in four groups of five, and stock's
    // enrollment screen places those groups on a column of five poses, tilted up at the top.
    // The middle one, straight on, has no code: it is captured first, while the user holds
    // still.
    private static final int POSE_CODE_FIRST = FACE_ACQUIRED_VENDOR_BASE + 101;
    private static final int POSE_CODE_LAST = FACE_ACQUIRED_VENDOR_BASE + 120;
    private static final int[] POSE_FOR_GROUP = {0, 1, 3, 4};
    private static final int POSE_CENTER = 2;

    // Frames arrive many times a second. A positioning hint stays up this long before the
    // pose prompt may replace it, or the text flickers between the two.
    private static final long HINT_HOLD_MS = 1000;

    private FaceManager mFaceManager;
    private CancellationSignal mCancel;
    private TextView mStatus;
    private CircleMaskView mMask;
    private PoseLightsView mPoses;
    private int mTotalSteps;

    private final boolean[] mLit = new boolean[PoseLightsView.COUNT];
    private int mLastPose = POSE_CENTER;
    private int mStage;
    private int mLastHelpCode = -1;
    private int mShownText;
    private long mHintUntil;

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
        mPoses = findViewById(R.id.poses);

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
        // The surface's size becomes the camera stream's, so the layout holds this at a
        // square the camera offers (see SquareFrameLayout). Deliberately no setFixedSize:
        // forcing a size changed the stream configuration and the camera pipeline could not
        // build its usual preview graph, so the frames arrived unprocessed. Stock hands over
        // a plain square SurfaceView the same way.
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
            // Progress means a pose was captured, and the straight-on one comes first, so
            // this also lights it for a HAL that never reports the stage.
            light(POSE_CENTER);
            if (remaining > 0) {
                return;
            }
            mStatus.setText(R.string.enroll_done);
            finishWith(RESULT_FINISHED, true);
        }

        // Every acquired message arrives here, with the stage and the face's position when
        // the HAL sends them. The framework's own text is no use for this HAL: it has none
        // for the pose codes, so the last hint stays on screen while the HAL waits for a
        // tilt, and it words the four direction hints the opposite way round to stock.
        @Override
        public void onEnrollmentFrame(int helpCode, CharSequence helpMessage,
                FaceEnrollCell cell, int stage, float pan, float tilt, float distance) {
            if (helpCode != mLastHelpCode || stage != mStage) {
                Log.d(TAG, "help " + helpCode + " stage " + stage + " pan " + pan
                        + " tilt " + tilt + " distance " + distance);
                mLastHelpCode = helpCode;
            }
            if (stage > 0) {
                mStage = stage;
                if (stage >= STAGE_HOLD_STILL_IN_CENTER) {
                    light(POSE_CENTER);
                }
            }
            if (helpCode >= POSE_CODE_FIRST && helpCode <= POSE_CODE_LAST) {
                mLastPose = POSE_FOR_GROUP[(helpCode - POSE_CODE_FIRST) / 5];
                light(mLastPose);
            }

            final long now = SystemClock.uptimeMillis();
            final int hint = positioningHint(helpCode);
            if (hint != 0) {
                mHintUntil = now + HINT_HOLD_MS;
                show(hint);
            } else if (now >= mHintUntil) {
                show(posePrompt());
            }
            mPoses.setState(mLit, targetPose());
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

    private void light(int pose) {
        mLit[pose] = true;
        mPoses.setState(mLit, targetPose());
    }

    /**
     * The pose to move towards: straight on until that is in, then the first one still
     * missing from the top down, as stock's screen points. -1 once all of them are in.
     */
    private int targetPose() {
        if (!mLit[POSE_CENTER]) {
            return POSE_CENTER;
        }
        for (int i = 0; i < mLit.length; i++) {
            if (!mLit[i]) {
                return i;
            }
        }
        return -1;
    }

    private int posePrompt() {
        final int target = targetPose();
        if (target < 0) {
            return R.string.enroll_keep_looking;
        }
        if (target == POSE_CENTER) {
            return R.string.enroll_center;
        }
        return target < mLastPose ? R.string.enroll_tilt_up : R.string.enroll_tilt_down;
    }

    // Stock's wording for the acquired codes that ask the user to move. The four direction
    // codes read the opposite way round to the framework's strings for them; this follows
    // stock, which ships with this HAL.
    private static int positioningHint(int helpCode) {
        switch (helpCode) {
            case 3: // FACE_ACQUIRED_TOO_DARK
                return R.string.enroll_too_dark;
            case 4: // FACE_ACQUIRED_TOO_CLOSE
                return R.string.enroll_too_close;
            case 5: // FACE_ACQUIRED_TOO_FAR
                return R.string.enroll_too_far;
            case 6: // FACE_ACQUIRED_TOO_HIGH
                return R.string.enroll_move_lower;
            case 7: // FACE_ACQUIRED_TOO_LOW
                return R.string.enroll_move_higher;
            case 8: // FACE_ACQUIRED_TOO_RIGHT
                return R.string.enroll_move_right;
            case 9: // FACE_ACQUIRED_TOO_LEFT
                return R.string.enroll_move_left;
            case 10: // FACE_ACQUIRED_POOR_GAZE
                return R.string.enroll_look_at_phone;
            case 21: // FACE_ACQUIRED_SENSOR_DIRTY
                return R.string.enroll_clean_camera;
            default:
                return 0;
        }
    }

    private void show(int text) {
        if (text != mShownText) {
            mShownText = text;
            mStatus.setText(text);
        }
    }

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
