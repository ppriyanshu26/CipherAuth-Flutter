package in.ppriyanshu.cipherauth;

import android.content.ContentResolver;
import android.content.ContentValues;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.view.WindowManager;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

public class MainActivity extends FlutterFragmentActivity {
    private static final String FLAVOR_CHANNEL = "cipherauth/flavor";
    private static final String STORAGE_CHANNEL = "cipherauth/storage";

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

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), STORAGE_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if ("saveToDownloads".equals(call.method)) {
                    String fileName = call.argument("fileName");
                    String content = call.argument("content");

                    if (fileName != null && content != null) {
                        boolean success = saveCsvToDownloads(fileName, content);
                        result.success(success ? "SUCCESS" : "FAILED");
                    } else {
                        result.error("INVALID_ARGUMENTS", "File name or content was null", null);
                    }
                } else {
                    result.notImplemented();
                }
            });
    }

    private boolean saveCsvToDownloads(String fileName, String content) {
        try {
            ContentResolver resolver = getContentResolver();
            ContentValues contentValues = new ContentValues(); 
            contentValues.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName);
            contentValues.put(MediaStore.MediaColumns.MIME_TYPE, "text/csv");

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                contentValues.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS);
            }

            Uri collectionUri = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q ? MediaStore.Downloads.EXTERNAL_CONTENT_URI : MediaStore.Files.getContentUri("external");
            Uri fileUri = resolver.insert(collectionUri, contentValues);
            if (fileUri != null) {
                try (OutputStream outputStream = resolver.openOutputStream(fileUri)) {
                    if (outputStream != null) {
                        outputStream.write(content.getBytes(StandardCharsets.UTF_8));
                        outputStream.flush();
                        return true;
                    }
                }
            }
            return false;
        } catch (Exception e) {
            return false;
        }
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