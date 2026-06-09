package `in`.ppriyanshu.cipherauth

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.autofill.AutofillService
import android.service.autofill.FillCallback
import android.service.autofill.FillContext
import android.service.autofill.FillRequest
import android.service.autofill.FillResponse
import android.service.autofill.SaveCallback
import android.service.autofill.SaveRequest
import android.view.autofill.AutofillId
import android.widget.RemoteViews


enum class AutofillNodeType {
    USERNAME, PASSWORD
}

data class AutofillNodeInfo(
    val id: AutofillId,
    val type: AutofillNodeType
)

class AutofillService : AutofillService() {

    override fun onFillRequest(request: FillRequest, cancellationSignal: android.os.CancellationSignal, callback: FillCallback) {
        val fillContexts = request.fillContexts
        if (fillContexts.isEmpty()) {
            callback.onSuccess(null)
            return
        }

        val structure = fillContexts.last().structure
        val packageName = structure.activityComponent.packageName

        val fields = mutableListOf<AutofillNodeInfo>()
        val domains = mutableSetOf<String>()
        
        val nodesCount = structure.windowNodeCount
        for (i in 0 until nodesCount) {
            val windowNode = structure.getWindowNodeAt(i)
            findAutofillFields(windowNode.rootViewNode, fields, domains)
        }

        val targetDomain = domains.firstOrNull() ?: ""

        if (fields.isEmpty()) {
            callback.onSuccess(null)
            return
        }

        val unlockIntent = Intent(this, AutofillUnlockActivity::class.java).apply {
            putExtra("target_package", packageName)
            putExtra("target_domain", targetDomain)
            
            val usernameNode = fields.firstOrNull { it.type == AutofillNodeType.USERNAME }
            val passwordNode = fields.firstOrNull { it.type == AutofillNodeType.PASSWORD }
            
            if (usernameNode != null) {
                putExtra("username_id", usernameNode.id)
            }
            if (passwordNode != null) {
                putExtra("password_id", passwordNode.id)
            }
        }

        val flag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_CANCEL_CURRENT
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            1001,
            unlockIntent,
            flag
        )

        val dropdownPresentation = RemoteViews(this.packageName, android.R.layout.simple_list_item_1).apply {
            setTextViewText(android.R.id.text1, "Unlock CipherAuth")
        }

        val responseBuilder = FillResponse.Builder()
        val targetIds = fields.map { it.id }.toTypedArray()

        responseBuilder.setAuthentication(
            targetIds,
            pendingIntent.intentSender,
            dropdownPresentation
        )

        callback.onSuccess(responseBuilder.build())
    }

    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        callback.onSuccess()
    }

    private fun findAutofillFields(node: android.app.assist.AssistStructure.ViewNode, fields: MutableList<AutofillNodeInfo>, domains: MutableSet<String>) {
        val webDomain = node.webDomain
        if (!webDomain.isNullOrEmpty()) {
            domains.add(webDomain)
        }

        val text = node.text?.toString() ?: ""
        if (text.startsWith("http://") || text.startsWith("https://")) {
            domains.add(text)
        }

        val hints = node.autofillHints
        val idEntry = node.idEntry
        val hintText = node.hint
        val className = node.className

        var isPassword = false
        var isUsername = false

        if (hints != null) {
            for (hint in hints) {
                if (hint.contains("password", ignoreCase = true)) {
                    isPassword = true
                }
                if (hint.contains("username", ignoreCase = true) || hint.contains("email", ignoreCase = true)) {
                    isUsername = true
                }
            }
        }

        val inputType = node.inputType
        if ((inputType and android.text.InputType.TYPE_MASK_CLASS) == android.text.InputType.TYPE_CLASS_TEXT) {
            val variation = inputType and android.text.InputType.TYPE_MASK_VARIATION
            if (variation == android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD ||
                variation == android.text.InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD ||
                variation == android.text.InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD) {
                isPassword = true
            }
        }

        if (idEntry != null) {
            val entry = idEntry.lowercase()
            if (entry.contains("password") || entry.contains("pwd") || entry.contains("pass")) {
                isPassword = true
            }
            if (entry.contains("username") || entry.contains("email") || entry.contains("login") || entry.contains("user")) {
                isUsername = true
            }
        }

        if (hintText != null) {
            val ht = hintText.toString().lowercase()
            if (ht.contains("password") || ht.contains("pwd") || ht.contains("pass")) {
                isPassword = true
            }
            if (ht.contains("username") || ht.contains("email") || ht.contains("login") || ht.contains("user")) {
                isUsername = true
            }
        }

        if (className != null && className.lowercase().contains("password")) {
            isPassword = true
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val htmlInfo = node.htmlInfo
            if (htmlInfo != null) {
                val attributes = htmlInfo.attributes
                if (attributes != null) {
                    for (pair in attributes) {
                        val key = pair.first?.lowercase() ?: ""
                        val value = pair.second?.lowercase() ?: ""
                        
                        if (key == "type") {
                            if (value.contains("password")) {
                                isPassword = true
                            }
                        }
                        if (key == "name" || key == "id" || key == "placeholder") {
                            if (value.contains("password") || value.contains("pwd") || value.contains("pass")) {
                                isPassword = true
                            }
                            if (value.contains("username") || value.contains("email") || value.contains("login") || value.contains("user")) {
                                isUsername = true
                            }
                        }
                    }
                }
            }
        }

        val autofillId = node.autofillId
        if (autofillId != null) {
            if (isPassword) {
                fields.add(AutofillNodeInfo(autofillId, AutofillNodeType.PASSWORD))
            } else if (isUsername) {
                fields.add(AutofillNodeInfo(autofillId, AutofillNodeType.USERNAME))
            }
        }

        for (i in 0 until node.childCount) {
            findAutofillFields(node.getChildAt(i), fields, domains)
        }
    }

}
