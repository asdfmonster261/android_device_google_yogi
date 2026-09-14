/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.faceenroll;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.RectF;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.view.View;

/**
 * Sits over the preview and hides everything outside a circle, with a ring that fills as
 * enrollment progresses. The preview is a SurfaceView on its own layer and cannot be
 * clipped, so the round shape is painted on top of it rather than applied to it.
 */
public class CircleMaskView extends View {

    private final Paint mHole = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint mTrack = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint mProgress = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final RectF mArc = new RectF();

    private final int mMaskColor;
    private final float mStroke;
    private float mFraction;

    public CircleMaskView(Context context, AttributeSet attrs) {
        super(context, attrs);
        // The hole is punched out of this view's own layer.
        setLayerType(LAYER_TYPE_HARDWARE, null);

        mStroke = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 6,
                getResources().getDisplayMetrics());
        mMaskColor = resolve(context, android.R.attr.colorBackground, 0xFF000000);
        final int accent = resolve(context, android.R.attr.colorAccent, 0xFF8AB4F8);

        mHole.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.CLEAR));
        mTrack.setStyle(Paint.Style.STROKE);
        mTrack.setStrokeWidth(mStroke);
        mTrack.setColor((accent & 0x00FFFFFF) | 0x33000000);
        mProgress.setStyle(Paint.Style.STROKE);
        mProgress.setStrokeWidth(mStroke);
        mProgress.setStrokeCap(Paint.Cap.ROUND);
        mProgress.setColor(accent);
    }

    private static int resolve(Context context, int attr, int fallback) {
        final TypedValue value = new TypedValue();
        if (context.getTheme().resolveAttribute(attr, value, true)) {
            return value.data;
        }
        return fallback;
    }

    /** 0 to 1, how much of the enrollment is done. */
    public void setFraction(float fraction) {
        mFraction = Math.max(0f, Math.min(1f, fraction));
        invalidate();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        final float cx = getWidth() / 2f;
        final float cy = getHeight() / 2f;
        final float radius = Math.min(cx, cy) - mStroke;

        canvas.drawColor(mMaskColor);
        canvas.drawCircle(cx, cy, radius, mHole);
        canvas.drawCircle(cx, cy, radius, mTrack);

        if (mFraction > 0f) {
            mArc.set(cx - radius, cy - radius, cx + radius, cy + radius);
            canvas.drawArc(mArc, -90f, 360f * mFraction, false, mProgress);
        }
    }
}
