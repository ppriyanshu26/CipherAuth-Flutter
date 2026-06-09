package `in`.ppriyanshu.cipherauth
import `in`.ppriyanshu.cipherauth.R
import `in`.ppriyanshu.cipherauth.MainActivity

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.view.autofill.AutofillId
import android.view.autofill.AutofillManager
import android.view.autofill.AutofillValue
import android.service.autofill.Dataset
import android.service.autofill.FillResponse
import android.text.InputType
import android.widget.Button
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.RemoteViews
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import org.json.JSONArray

data class Credential(val id: String, val name: String, val domain: String, val username: String, val password: String, val notes: String)

class AutofillUnlockActivity : FragmentActivity() {
    private lateinit var tvDomainInfo: TextView
    private lateinit var biometricStatusContainer: LinearLayout
    private lateinit var passwordSectionContainer: LinearLayout
    
    private lateinit var masterPasswordInput: EditText
    private lateinit var tvPasswordError: TextView
    private lateinit var btnUnlock: Button
    private lateinit var textCancel: TextView

    private var targetPackage: String = ""
    private var targetDomain: String = ""
    private var usernameId: AutofillId? = null
    private var passwordId: AutofillId? = null
    private var isPasswordVisible = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )

        setContentView(R.layout.activity_autofill_unlock)

        targetPackage = intent.getStringExtra("target_package") ?: ""
        targetDomain = intent.getStringExtra("target_domain") ?: ""
        
        usernameId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra("username_id", AutofillId::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra("username_id")
        }
        
        passwordId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra("password_id", AutofillId::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra("password_id")
        }

        tvDomainInfo = findViewById(R.id.tv_domain_info)
        biometricStatusContainer = findViewById(R.id.biometric_status_container)
        passwordSectionContainer = findViewById(R.id.password_section_container)
        
        masterPasswordInput = findViewById(R.id.master_password_input)
        tvPasswordError = findViewById(R.id.tv_password_error)
        btnUnlock = findViewById(R.id.btn_unlock)
        textCancel = findViewById(R.id.text_cancel)

        val btnTogglePasswordVisibility = findViewById<ImageView>(R.id.btn_toggle_password_visibility)
        btnTogglePasswordVisibility.setOnClickListener {
            isPasswordVisible = !isPasswordVisible
            if (isPasswordVisible) {
                masterPasswordInput.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD
                btnTogglePasswordVisibility.setImageResource(R.drawable.ic_visibility)
            } else {
                masterPasswordInput.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
                btnTogglePasswordVisibility.setImageResource(R.drawable.ic_visibility_off)
            }
            masterPasswordInput.setSelection(masterPasswordInput.text.length)
        }

        val domainTld = DomainUtils.extractDomainTld(targetDomain)
        if (domainTld.isNotEmpty()) {
            tvDomainInfo.text = "Filling for $domainTld"
        } else if (targetPackage.isNotEmpty()) {
            tvDomainInfo.text = "Filling for app: $targetPackage"
        } else {
            tvDomainInfo.text = "Filling credentials"
        }

        val isBioEnabled = AutofillKeyStoreHelper.isBiometricEnabled(this)

        if (isBioEnabled) {
            showBiometricPrompt()
        } else {
            showPasswordPrompt()
        }

        btnUnlock.setOnClickListener {
            val enteredPassword = masterPasswordInput.text.toString()
            if (enteredPassword.isEmpty()) {
                tvPasswordError.text = "Password cannot be empty."
                tvPasswordError.visibility = View.VISIBLE
                return@setOnClickListener
            }
            processUnlock(enteredPassword)
        }

        textCancel.setOnClickListener {
            setResult(Activity.RESULT_CANCELED)
            finish()
        }
    }

    private fun showBiometricPrompt() {
        val executor = ContextCompat.getMainExecutor(this)
        val biometricPrompt = BiometricPrompt(this, executor, object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                super.onAuthenticationError(errorCode, errString)
                runOnUiThread {
                    showPasswordPrompt()
                    if (errorCode != BiometricPrompt.ERROR_USER_CANCELED && errorCode != BiometricPrompt.ERROR_NEGATIVE_BUTTON) {
                        tvPasswordError.text = errString
                        tvPasswordError.visibility = View.VISIBLE
                    }
                }
            }

            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                super.onAuthenticationSucceeded(result)
                runOnUiThread {
                    val decryptedMasterPassword = AutofillKeyStoreHelper.decryptMasterPassword(this@AutofillUnlockActivity)
                    if (decryptedMasterPassword != null) {
                        processUnlock(decryptedMasterPassword)
                    } else {
                        showPasswordPrompt()
                        tvPasswordError.text = "Could not retrieve password. Please enter it manually."
                        tvPasswordError.visibility = View.VISIBLE
                    }
                }
            }

            override fun onAuthenticationFailed() {
                super.onAuthenticationFailed()
            }
        })

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Unlock CipherAuth")
            .setSubtitle("Authenticate to autofill credentials")
            .setNegativeButtonText("Use Password")
            .build()

        biometricStatusContainer.visibility = View.VISIBLE
        passwordSectionContainer.visibility = View.GONE
        
        biometricPrompt.authenticate(promptInfo)
    }

    private fun showPasswordPrompt() {
        biometricStatusContainer.visibility = View.GONE
        passwordSectionContainer.visibility = View.VISIBLE
        masterPasswordInput.requestFocus()
    }

    private fun processUnlock(masterPassword: String) {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val encryptedTotpStore = prefs.getString("flutter.totp_store", null)
            val encryptedStore = prefs.getString("flutter.password_store", null)

            if (!encryptedTotpStore.isNullOrEmpty()) {
                PasswordStoreDecryptor.decryptStore(encryptedTotpStore, masterPassword)
            } else if (!encryptedStore.isNullOrEmpty()) {
                PasswordStoreDecryptor.decryptStore(encryptedStore, masterPassword)
            } else {
                returnAutofillResponse(emptyList())
                return
            }
            if (encryptedStore.isNullOrEmpty()) {
                returnAutofillResponse(emptyList())
                return
            }

            val decryptedJson = PasswordStoreDecryptor.decryptStore(encryptedStore, masterPassword)
            val credentials = parseCredentialsJson(decryptedJson)
            val matches = credentials.filter {
                DomainUtils.matchesPackageOrDomain(it.domain, targetDomain, targetPackage)
            }
            returnAutofillResponse(matches)
        } catch (e: Exception) {
            showPasswordPrompt()
            tvPasswordError.text = "Incorrect password."
            tvPasswordError.visibility = View.VISIBLE
        }
    }

    private fun parseCredentialsJson(jsonStr: String): List<Credential> {
        val list = mutableListOf<Credential>()
        val array = JSONArray(jsonStr)
        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            list.add(
                Credential(
                    id = obj.optString("id"),
                    name = obj.optString("name"),
                    domain = obj.optString("domain"),
                    username = obj.optString("username"),
                    password = obj.optString("password"),
                    notes = obj.optString("notes")
                )
            )
        }
        return list
    }

    private fun returnAutofillResponse(matches: List<Credential>) {
        val replyIntent = Intent()
        val responseBuilder = FillResponse.Builder()

        for (cred in matches) {
            val datasetBuilder = Dataset.Builder()
            val usernamePresentation = RemoteViews(packageName, android.R.layout.simple_list_item_1).apply {
                setTextViewText(android.R.id.text1, cred.username)
            }

            if (usernameId != null) {
                datasetBuilder.setValue(usernameId!!, AutofillValue.forText(cred.username), usernamePresentation)
            }

            if (passwordId != null) {
                val passwordPresentation = RemoteViews(packageName, android.R.layout.simple_list_item_1).apply {
                    setTextViewText(android.R.id.text1, cred.username)
                }
                datasetBuilder.setValue(passwordId!!, AutofillValue.forText(cred.password), passwordPresentation)
            }

            try {
                responseBuilder.addDataset(datasetBuilder.build())
            } catch (e: Exception) {
                //
            }
        }

        if (matches.isEmpty()) {
            val infoDatasetBuilder = Dataset.Builder()
            val infoPresentation = RemoteViews(packageName, android.R.layout.simple_list_item_1).apply {
                setTextViewText(android.R.id.text1, "No matching accounts")
            }
            if (usernameId != null) {
                infoDatasetBuilder.setValue(usernameId!!, null, infoPresentation)
            }
            if (passwordId != null) {
                infoDatasetBuilder.setValue(passwordId!!, null, infoPresentation)
            }
            try {
                responseBuilder.addDataset(infoDatasetBuilder.build())
            } catch (e: Exception) {
                // 
            }
        }

        val openAppDatasetBuilder = Dataset.Builder()
        val openAppPresentation = RemoteViews(packageName, android.R.layout.simple_list_item_1).apply {
            setTextViewText(android.R.id.text1, "Open CipherAuth")
        }

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this,
            1002,
            openAppIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_IMMUTABLE else 0
        )

        if (usernameId != null) {
            openAppDatasetBuilder.setValue(usernameId!!, null, openAppPresentation)
        }
        if (passwordId != null) {
            openAppDatasetBuilder.setValue(passwordId!!, null, openAppPresentation)
        }

        openAppDatasetBuilder.setAuthentication(openAppPendingIntent.intentSender)

        try {
            responseBuilder.addDataset(openAppDatasetBuilder.build())
        } catch (e: Exception) {
            // 
        }

        replyIntent.putExtra(AutofillManager.EXTRA_AUTHENTICATION_RESULT, responseBuilder.build())
        setResult(Activity.RESULT_OK, replyIntent)
        
        finish()
    }
}
