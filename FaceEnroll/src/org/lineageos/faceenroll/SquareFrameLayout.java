/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.faceenroll;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.FrameLayout;

/**
 * Keeps the preview square so the circular mask over it is actually a circle, and no more
 * than PREVIEW_PX across. The preview surface's size becomes the camera stream's, and both
 * front cameras only take squares of 1080 and 1920. 1080 is the one proven alongside the
 * HAL's own stream, and it fits both screens: the cover screen is exactly that wide, and
 * unfolded the square would otherwise come out at 1908, which the camera refuses.
 */
public class SquareFrameLayout extends FrameLayout {

    private static final int PREVIEW_PX = 1080;

    public SquareFrameLayout(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        final int size = Math.min(PREVIEW_PX, Math.min(MeasureSpec.getSize(widthMeasureSpec),
                MeasureSpec.getSize(heightMeasureSpec)));
        final int spec = MeasureSpec.makeMeasureSpec(size, MeasureSpec.EXACTLY);
        super.onMeasure(spec, spec);
    }
}
