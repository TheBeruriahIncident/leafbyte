/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.view;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;

import com.thebluefolderproject.leafbyte.utils.ConstantsKt;

/**
 * Zooming view.
 *
 * Adapted from https://github.com/Polidea/android-zoom-view/blob/master/src/pl/polidea/view/ZoomView.java
 */
public class ZoomView extends FrameLayout {
    private static final float MIN_ZOOM = 1.0f;
    private static final float DOUBLE_TAP_ZOOM = 4.0f;
    private static final float MAX_ZOOM = 50.0f;

    // zooming
    float currentZoom = MIN_ZOOM;
    float targetZoom = MIN_ZOOM;
    float currentXOffset = 0, currentYOffset = 0;
    float targetXOffset = 0, targetYOffset = 0;
    private boolean scrolling;

    // touching variables
    private long lastTapTime;
    private float lastTouchX, lastTouchY;
    private float startd;
    private boolean pinching;
    private float lastd;
    private float lastTouchX1, lastTouchY1;
    private float lastTouchX2, lastTouchY2;

    // drawing
    private final Matrix matrix = new Matrix();

    public ZoomView(final Context context) {
        super(context);
    }

    public ZoomView(Context context, AttributeSet attrs)
    {
        super(context, attrs);
    }

    private void smoothZoomTo(float requestedZoom, float x, float y) {
        targetZoom = clamp(MIN_ZOOM, requestedZoom, MAX_ZOOM);
        targetXOffset = x;
        targetYOffset = y;
    }

    @Override
    public boolean dispatchTouchEvent(final MotionEvent motionEvent) {
        // single touch
        if (motionEvent.getPointerCount() == 1) {
            processSingleTouchEvent(motionEvent);
        }

        // // double touch
        if (motionEvent.getPointerCount() == 2) {
            processDoubleTouchEvent(motionEvent);
        }

        super.dispatchTouchEvent(motionEvent);

        // redraw
        getRootView().invalidate();
        invalidate();

        return true;
    }

    private void processSingleTouchEvent(MotionEvent motionEvent) {
        final float touchX = motionEvent.getX();
        final float touchY = motionEvent.getY();
        float touchDx = touchX - lastTouchX;
        float touchDy = touchY - lastTouchY;
        final float touchDistance = (float) Math.hypot(touchDx, touchDy);
        lastTouchX = touchX;
        lastTouchY = touchY;

        switch (motionEvent.getAction()) {
            case MotionEvent.ACTION_DOWN:
                lastTouchX = touchX;
                lastTouchY = touchY;
                scrolling = false;
                break;

            case MotionEvent.ACTION_MOVE:
                if (scrolling || (targetZoom > 1.0f && touchDistance > 30.0f)) {
                    if (!scrolling) {
                        scrolling = true;
                        motionEvent.setAction(MotionEvent.ACTION_CANCEL);
                        super.dispatchTouchEvent(motionEvent);
                    }
                    targetXOffset -= touchDx / currentZoom;
                    targetYOffset -= touchDy / currentZoom;
                    return;
                }
                break;

            case MotionEvent.ACTION_OUTSIDE:
            case MotionEvent.ACTION_UP:

                // tap
                if (touchDistance < 30.0f) {
                    // check double tap
                    if (System.currentTimeMillis() - lastTapTime < 500) {
                        if (targetZoom == MIN_ZOOM) {
                            smoothZoomTo(DOUBLE_TAP_ZOOM, touchX, touchY);
                        } else {
                            smoothZoomTo(MIN_ZOOM, getWidth() / 2.0f, getHeight() / 2.0f);
                        }
                        lastTapTime = 0;
                        motionEvent.setAction(MotionEvent.ACTION_CANCEL);
                        super.dispatchTouchEvent(motionEvent);
                        return;
                    }

                    lastTapTime = System.currentTimeMillis();

                    performClick();
                }
                break;

            default:
                break;
        }

        motionEvent.setLocation(currentXOffset + (touchX - 0.5f * getWidth()) / currentZoom, currentYOffset + (touchY - 0.5f * getHeight()) / currentZoom);

        motionEvent.getX();
        motionEvent.getY();
    }

    private void processDoubleTouchEvent(final MotionEvent motionEvent) {
        final float touchX1 = motionEvent.getX(0);
        final float touchDx1 = touchX1 - lastTouchX1;
        lastTouchX1 = touchX1;
        final float touchY1 = motionEvent.getY(0);
        final float touchDy1 = touchY1 - lastTouchY1;
        lastTouchY1 = touchY1;
        final float touchX2 = motionEvent.getX(1);
        final float touchDx2 = touchX2 - lastTouchX2;
        lastTouchX2 = touchX2;
        final float touchY2 = motionEvent.getY(1);
        final float touchDy2 = touchY2 - lastTouchY2;
        lastTouchY2 = touchY2;

        // pointers distance
        final float d = (float) Math.hypot(touchX2 - touchX1, touchY2 - touchY1);
        final float dd = d - lastd;
        lastd = d;
        final float ld = Math.abs(d - startd);

        switch (motionEvent.getAction()) {
            case MotionEvent.ACTION_DOWN:
                startd = d;
                pinching = false;
                break;

            case MotionEvent.ACTION_MOVE:
                if (pinching || ld > 30.0f) {
                    pinching = true;
                    final float dxk = 0.5f * (touchDx1 + touchDx2);
                    final float dyk = 0.5f * (touchDy1 + touchDy2);
                    smoothZoomTo(Math.max(1.0f, currentZoom * d / (d - dd)), currentXOffset - dxk / currentZoom, currentYOffset - dyk / currentZoom);
                }

                break;

            case MotionEvent.ACTION_UP:
            default:
                pinching = false;
                break;
        }

        motionEvent.setAction(MotionEvent.ACTION_CANCEL);
    }

    private float clamp(final float min, final float value, final float max) {
        return Math.max(min, Math.min(value, max));
    }

    private float lerp(final float start, final float end, final float amountToInterpolate) {
        return start + (end - start) * amountToInterpolate;
    }

    private float bias(final float a, final float b, final float k) {
        return Math.abs(b - a) >= k ? a + k * Math.signum(b - a) : b;
    }

    @Override
    protected void dispatchDraw(final Canvas canvas) {
        //ConstantsKt.log("x "+ currentXOffset + " y "+ currentYOffset);
        // do zoom
        currentZoom = lerp(bias(currentZoom, targetZoom, 0.05f), targetZoom, 0.2f);
        targetXOffset = clamp(0.5f * getWidth() / targetZoom, targetXOffset, getWidth() - 0.5f * getWidth() / targetZoom);
        targetYOffset = clamp(0.5f * getHeight() / targetZoom, targetYOffset, getHeight() - 0.5f * getHeight() / targetZoom);

        currentXOffset = lerp(bias(currentXOffset, targetXOffset, 0.1f), targetXOffset, 0.35f);
        currentYOffset = lerp(bias(currentYOffset, targetYOffset, 0.1f), targetYOffset, 0.35f);

        // nothing to draw
        if (getChildCount() == 0) {
            return;
        }

        // prepare matrix
        matrix.setTranslate(0.5f * getWidth(), 0.5f * getHeight());
        matrix.preScale(currentZoom, currentZoom);
        matrix.preTranslate(-clamp(0.5f * getWidth() / currentZoom, currentXOffset, getWidth() - 0.5f * getWidth() / currentZoom),
                -clamp(0.5f * getHeight() / currentZoom, currentYOffset, getHeight() - 0.5f * getHeight() / currentZoom));

        // get view
        final View childView = getChildAt(0);
        matrix.preTranslate(childView.getLeft(), childView.getTop());

        canvas.save();
        canvas.concat(matrix);
        childView.draw(canvas);
        canvas.restore();

        // redraw
        getRootView().invalidate();
        invalidate();
    }
}
