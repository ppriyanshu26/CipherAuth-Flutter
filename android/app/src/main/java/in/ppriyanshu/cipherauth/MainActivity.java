package in.ppriyanshu.cipherauth;

import android.view.WindowManager;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterFragmentActivity {
    private static final String FLAVOR_CHANNEL = "cipherauth/flavor";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), FLAVOR_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if ("getFlavor".equals(call.method)) {
                    result.success(BuildConfig.FLAVOR);
                } else {
                    result.notImplemented();
                }
            });
    }

    @Override
    protected void onResume() {
        super.onResume();

        if (isSampleFlavor()) {
            disableSecureWindow();
            return;
        }

        enableSecureWindow();
    }

    private boolean isSampleFlavor() {
        return "sample".equals(BuildConfig.FLAVOR);
    }

    private void enableSecureWindow() {
        getWindow().setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        );
    }

    private void disableSecureWindow() {
        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
    }
}
