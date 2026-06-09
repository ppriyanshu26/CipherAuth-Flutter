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
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.provider.Settings;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

public class MainActivity extends FlutterFragmentActivity {
    private static final String FLAVOR_CHANNEL = "cipherauth/flavor";
    private static final String STORAGE_CHANNEL = "cipherauth/storage";
    private static final String AUTOFILL_CHANNEL = "cipherauth/autofill";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), AUTOFILL_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "isAutofillEnabled": {
                        boolean enabled = false;
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            String setting = Settings.Secure.getString(getContentResolver(), "autofill_service");
                            if (setting != null) {
                                enabled = setting.contains(getPackageName() + "/in.ppriyanshu.cipherauth.AutofillService");
                            }
                        }
                        result.success(enabled);
                        break;
                    }
                    case "openAutofillSettings": {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Intent intent = new Intent(Settings.ACTION_REQUEST_SET_AUTOFILL_SERVICE);
                            intent.setData(Uri.parse("package:" + getPackageName()));
                            try {
                                startActivity(intent);
                                result.success(true);
                            } catch (Exception e) {
                                try {
                                    startActivity(new Intent(Settings.ACTION_SETTINGS));
                                    result.success(true);
                                } catch (Exception ex) {
                                    result.error("FAILED", "Could not open autofill settings", ex.getMessage());
                                }
                            }
                        } else {
                            result.error("NOT_SUPPORTED", "Autofill not supported on this device", null);
                        }
                        break;
                    }
                    case "enableBiometricAutofill": {
                        String password = call.argument("password");
                        if (password != null) {
                            AutofillKeyStoreHelper.INSTANCE.encryptAndSaveMasterPassword(this, password);
                            result.success(true);
                        } else {
                            result.error("INVALID_ARGUMENTS", "Password was null", null);
                        }
                        break;
                    }
                    case "disableBiometricAutofill": {
                        AutofillKeyStoreHelper.INSTANCE.disableBiometric(this);
                        result.success(true);
                        break;
                    }
                    default:
                        result.notImplemented();
                        break;
                }
            });

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