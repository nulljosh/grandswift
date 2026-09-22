package com.jaybulb.rainjack;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

// Android shell around the web build.
public class MainActivity extends Activity {
    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        WebView v = new WebView(this);
        WebSettings s = v.getSettings();
        s.setJavaScriptEnabled(true); s.setDomStorageEnabled(true); s.setMediaPlaybackRequiresUserGesture(false);
        v.setWebViewClient(new WebViewClient());
        v.loadUrl("https://grandswift.heyitsmejosh.com/play.html");
        setContentView(v);
    }
}
