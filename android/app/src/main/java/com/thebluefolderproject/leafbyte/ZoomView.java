package com.thebluefolderproject.leafbyte;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.util.AttributeSet;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;

/**
 * Zooming view.
 *
 * Adapted from https://github.com/Polidea/android-zoom-view/blob/master/src/pl/polidea/view/ZoomView.java
 */
public class ZoomView extends FrameLayout {

    // zooming
    float zoom = 1.0f;
    float maxZoom = 50.0f;
    float smoothZoom = 1.0f;
    float zoomX, zoomY;
    float smoothZoomX, smoothZoomY;
    private boolean scrolling; // NOPMD by karooolek on 29.06.11 11:45

    // touching variables
    private long lastTapTime;
    private float touchStartX, touchStartY;
    private float touchLastX, touchLastY;
    private float startd;
    private boolean pinching;
    private float lastd;
    private float lastdx1, lastdy1;
    private float lastdx2, lastdy2;

    // drawing
    private final Matrix matrix = new Matrix();

    public ZoomView(final Context context) {
        super(context);
    }

    public ZoomView(Context context, AttributeSet attrs)
    {
        super(context, attrs);
    }

    public void zoomTo(final float zoom, final float x, final float y) {
        this.zoom = Math.min(zoom, maxZoom);
        zoomX = x;
        zoomY = y;
        smoothZoomTo(this.zoom, x, y);
    }

    public void smoothZoomTo(final float zoom, final float x, final float y) {
        smoothZoom = clamp(1.0f, zoom, maxZoom);
        smoothZoomX = x;
        smoothZoomY = y;
    }

    @Override
    public boolean dispatchTouchEvent(final MotionEvent ev) {
        // single touch
        if (ev.getPointerCount() == 1) {
            processSingleTouchEvent(ev);
        }

        // // double touch
        if (ev.getPointerCount() == 2) {
            processDoubleTouchEvent(ev);
        }

        super.dispatchTouchEvent(ev);

        // redraw
        getRootView().invalidate();
        invalidate();

        return true;
    }

    private void processSingleTouchEvent(final MotionEvent ev) {
        final float x = ev.getX();
        final float y = ev.getY();
        float dx = x - touchLastX;
        float dy = y - touchLastY;
        final float l = (float) Math.hypot(dx, dy);
        touchLastX = x;
        touchLastY = y;

        switch (ev.getAction()) {
            case MotionEvent.ACTION_DOWN:
                touchStartX = x;
                touchStartY = y;
                touchLastX = x;
                touchLastY = y;
                scrolling = false;
                break;

            case MotionEvent.ACTION_MOVE:
                if (scrolling || (smoothZoom > 1.0f && l > 30.0f)) {
                    if (!scrolling) {
                        scrolling = true;
                        ev.setAction(MotionEvent.ACTION_CANCEL);
                        super.dispatchTouchEvent(ev);
                    }
                    smoothZoomX -= dx / zoom;
                    smoothZoomY -= dy / zoom;
                    return;
                }
                break;

            case MotionEvent.ACTION_OUTSIDE:
            case MotionEvent.ACTION_UP:

                // tap
                if (l < 30.0f) {
                    // check double tap
                    if (System.currentTimeMillis() - lastTapTime < 500) {
                        if (smoothZoom == 1.0f) {
                            smoothZoomTo(maxZoom, x, y);
                        } else {
                            smoothZoomTo(1.0f, getWidth() / 2.0f, getHeight() / 2.0f);
                        }
                        lastTapTime = 0;
                        ev.setAction(MotionEvent.ACTION_CANCEL);
                        super.dispatchTouchEvent(ev);
                        return;
                    }

                    lastTapTime = System.currentTimeMillis();

                    performClick();
                }
                break;

            default:
                break;
        }

        ev.setLocation(zoomX + (x - 0.5f * getWidth()) / zoom, zoomY + (y - 0.5f * getHeight()) / zoom);

        ev.getX();
        ev.getY();
    }

    private void processDoubleTouchEvent(final MotionEvent ev) {
        final float x1 = ev.getX(0);
        final float dx1 = x1 - lastdx1;
        lastdx1 = x1;
        final float y1 = ev.getY(0);
        final float dy1 = y1 - lastdy1;
        lastdy1 = y1;
        final float x2 = ev.getX(1);
        final float dx2 = x2 - lastdx2;
        lastdx2 = x2;
        final float y2 = ev.getY(1);
        final float dy2 = y2 - lastdy2;
        lastdy2 = y2;

        // pointers distance
        final float d = (float) Math.hypot(x2 - x1, y2 - y1);
        final float dd = d - lastd;
        lastd = d;
        final float ld = Math.abs(d - startd);

        Math.atan2(y2 - y1, x2 - x1);
        switch (ev.getAction()) {
            case MotionEvent.ACTION_DOWN:
                startd = d;
                pinching = false;
                break;

            case MotionEvent.ACTION_MOVE:
                if (pinching || ld > 30.0f) {
                    pinching = true;
                    final float dxk = 0.5f * (dx1 + dx2);
                    final float dyk = 0.5f * (dy1 + dy2);
                    smoothZoomTo(Math.max(1.0f, zoom * d / (d - dd)), zoomX - dxk / zoom, zoomY - dyk / zoom);
                }

                break;

            case MotionEvent.ACTION_UP:
            default:
                pinching = false;
                break;
        }

        ev.setAction(MotionEvent.ACTION_CANCEL);
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
        // do zoom
        zoom = lerp(bias(zoom, smoothZoom, 0.05f), smoothZoom, 0.2f);
        smoothZoomX = clamp(0.5f * getWidth() / smoothZoom, smoothZoomX, getWidth() - 0.5f * getWidth() / smoothZoom);
        smoothZoomY = clamp(0.5f * getHeight() / smoothZoom, smoothZoomY, getHeight() - 0.5f * getHeight() / smoothZoom);

        zoomX = lerp(bias(zoomX, smoothZoomX, 0.1f), smoothZoomX, 0.35f);
        zoomY = lerp(bias(zoomY, smoothZoomY, 0.1f), smoothZoomY, 0.35f);

        // nothing to draw
        if (getChildCount() == 0) {
            return;
        }

        // prepare matrix
        matrix.setTranslate(0.5f * getWidth(), 0.5f * getHeight());
        matrix.preScale(zoom, zoom);
        matrix.preTranslate(-clamp(0.5f * getWidth() / zoom, zoomX, getWidth() - 0.5f * getWidth() / zoom),
                -clamp(0.5f * getHeight() / zoom, zoomY, getHeight() - 0.5f * getHeight() / zoom));

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
