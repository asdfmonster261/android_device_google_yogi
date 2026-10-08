/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.faceenroll;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.util.AttributeSet;
import android.view.View;

import java.util.Arrays;

/**
 * A column of lights for the head poses enrollment needs, tilted up at the top, straight
 * on in the middle and tilted down at the bottom. A ring marks the one to move towards.
 */
public class PoseLightsView extends View {

    public static final int COUNT = 5;

    private final Paint mOn = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint mOff = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint mRing = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final float mRadius;
    private final float mGap;
    private final float mStroke;

    private final boolean[] mLit = new boolean[COUNT];
    private int mTarget = -1;

    public PoseLightsView(Context context, AttributeSet attrs) {
        super(context, attrs);
        final float density = getResources().getDisplayMetrics().density;
        mRadius = 5 * density;
        mGap = 14 * density;
        mStroke = 2 * density;

        final int accent = CircleMaskView.resolve(context, android.R.attr.colorAccent,
                0xFF8AB4F8);
        mOn.setColor(accent);
        mOff.setColor((accent & 0x00FFFFFF) | 0x33000000);
        mRing.setStyle(Paint.Style.STROKE);
        mRing.setStrokeWidth(mStroke);
        mRing.setColor(accent);
    }

    /** Which poses are captured, and the one to move towards, or -1 for none. */
    public void setState(boolean[] lit, int target) {
        if (target == mTarget && Arrays.equals(lit, mLit)) {
            return;
        }
        System.arraycopy(lit, 0, mLit, 0, COUNT);
        mTarget = target;
        invalidate();
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        final float ring = mRadius + 2 * mStroke;
        final int width = (int) Math.ceil(2 * ring) + getPaddingLeft() + getPaddingRight();
        final int height = (int) Math.ceil(COUNT * 2 * ring + (COUNT - 1) * mGap)
                + getPaddingTop() + getPaddingBottom();
        setMeasuredDimension(resolveSize(width, widthMeasureSpec),
                resolveSize(height, heightMeasureSpec));
    }

    @Override
    protected void onDraw(Canvas canvas) {
        final float ring = mRadius + 2 * mStroke;
        final float step = 2 * ring + mGap;
        final float cx = getWidth() / 2f;
        float cy = (getHeight() - (COUNT * 2 * ring + (COUNT - 1) * mGap)) / 2f + ring;

        for (int i = 0; i < COUNT; i++, cy += step) {
            canvas.drawCircle(cx, cy, mRadius, mLit[i] ? mOn : mOff);
            if (i == mTarget) {
                canvas.drawCircle(cx, cy, mRadius + mStroke, mRing);
            }
        }
    }
}
