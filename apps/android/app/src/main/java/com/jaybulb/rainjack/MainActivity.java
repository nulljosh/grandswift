package com.jaybulb.rainjack;

import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

public class MainActivity extends Activity {
    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        FrameLayout root = new FrameLayout(this);
        WebView web = new WebView(this);
        web.setBackgroundColor(Color.rgb(17, 17, 17));
        WebSettings settings = web.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setMediaPlaybackRequiresUserGesture(false);
        root.addView(web, new FrameLayout.LayoutParams(-1, -1));

        LinearLayout splash = new LinearLayout(this);
        splash.setOrientation(LinearLayout.VERTICAL);
        splash.setGravity(Gravity.CENTER);
        splash.setBackgroundColor(Color.rgb(17, 17, 17));
        ImageView icon = new ImageView(this);
        icon.setImageResource(R.drawable.brand);
        icon.setContentDescription("Vancouver Vice");
        int size = Math.round(96 * getResources().getDisplayMetrics().density);
        splash.addView(icon, new LinearLayout.LayoutParams(size, size));
        TextView status = new TextView(this);
        status.setText(R.string.loading);
        status.setTextColor(Color.WHITE);
        status.setPadding(16, 16, 16, 16);
        status.setAccessibilityLiveRegion(View.ACCESSIBILITY_LIVE_REGION_POLITE);
        splash.addView(status);
        root.addView(splash, new FrameLayout.LayoutParams(-1, -1));
        setContentView(root);
        web.setWebViewClient(new WebViewClient() {
            private boolean failed;
            @Override public void onPageStarted(WebView view, String url, android.graphics.Bitmap favicon) {
                failed = false;
            }
            private void showError() {
                failed = true;
                status.setText(R.string.load_failed);
                splash.setVisibility(View.VISIBLE);
                splash.setOnClickListener(v -> {
                    status.setText(R.string.loading);
                    splash.setOnClickListener(null);
                    web.loadUrl("https://vancouvervice.heyitsmejosh.com/play.html");
                });
            }
            @Override public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
                if (request.isForMainFrame()) showError();
            }
            @Override public void onReceivedHttpError(WebView view, WebResourceRequest request, WebResourceResponse response) {
                if (request.isForMainFrame()) showError();
            }
            @Override public void onPageFinished(WebView view, String url) {
                if (!failed) splash.setVisibility(View.GONE);
            }
        });
        web.loadUrl("https://vancouvervice.heyitsmejosh.com/play.html");
    }
}
