package com.cipherowl.cipherowl

import android.app.assist.AssistStructure
import android.os.Build
import android.os.CancellationSignal
import android.service.autofill.*
import android.view.autofill.AutofillId
import android.view.autofill.AutofillValue
import android.widget.RemoteViews
import androidx.annotation.RequiresApi
import org.json.JSONArray
import android.content.Context

// ─────────────────────────────────────────────────────────────────────────────
//  CipherOwlAutofillService
//
//  Reads a credential cache written by Flutter (via MethodChannel) into
//  SharedPreferences and fills username/password fields when Android
//  requests autofill.
//
//  Flutter side (autofill_bridge.dart) serialises credentials as:
//    KEY_CACHE  →  JSON array of { id, title, username, password, url }
// ─────────────────────────────────────────────────────────────────────────────
@RequiresApi(Build.VERSION_CODES.O)
class CipherOwlAutofillService : AutofillService() {

    companion object {
        /** SharedPreferences file name — must match autofill_bridge.dart */
        const val PREFS_NAME = "cipher_owl_autofill"

        /** Key inside the prefs file that holds the JSON blob */
        const val KEY_CACHE  = "credential_cache"
    }

    // ── Autofill request ────────────────────────────────────────────────────

    override fun onFillRequest(
        request: FillRequest,
        cancellationSignal: CancellationSignal,
        callback: FillCallback,
    ) {
        val structure = request.fillContexts.lastOrNull()?.structure
            ?: return callback.onSuccess(null)

        // Parse the window hierarchy to find autofill-able fields
        val parsed = parseStructure(structure)
        if (parsed.usernameIds.isEmpty() && parsed.passwordIds.isEmpty()) {
            return callback.onSuccess(null)
        }

        // Load credentials from the Flutter-written cache
        val credentials = loadCachedCredentials()
        if (credentials.isEmpty()) {
            return callback.onSuccess(null)
        }

        // Filter: if we have a package name or web domain, prefer matching ones
        val appPackage  = structure.activityComponent?.packageName ?: ""
        val webDomain   = parsed.webDomain ?: ""

        val ranked = credentials.sortedByDescending { cred ->
            when {
                webDomain.isNotBlank() && cred.url.contains(webDomain, ignoreCase = true) -> 2
                appPackage.isNotBlank() && cred.url.contains(appPackage, ignoreCase = true) -> 1
                else -> 0
            }
        }

        val responseBuilder = FillResponse.Builder()

        for (cred in ranked.take(5)) {   // cap at 5 suggestions
            val dataset = buildDataset(cred, parsed)
            dataset?.let { responseBuilder.addDataset(it) }
        }

        // Save callback — let Android ask CipherOwl to save newly typed creds
        if (parsed.usernameIds.isNotEmpty() && parsed.passwordIds.isNotEmpty()) {
            val saveInfo = SaveInfo.Builder(
                SaveInfo.SAVE_DATA_TYPE_USERNAME or SaveInfo.SAVE_DATA_TYPE_PASSWORD,
                (parsed.usernameIds + parsed.passwordIds).toTypedArray(),
            ).build()
            responseBuilder.setSaveInfo(saveInfo)
        }

        callback.onSuccess(responseBuilder.build())
    }

    // ── Save request ────────────────────────────────────────────────────────

    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        // Future: persist new credentials back to the Flutter vault
        // For now just acknowledge
        callback.onSuccess()
    }

    // ── Structure parser ────────────────────────────────────────────────────

    private data class ParsedStructure(
        val usernameIds: List<AutofillId>,
        val passwordIds: List<AutofillId>,
        val webDomain: String?,
    )

    private fun parseStructure(structure: AssistStructure): ParsedStructure {
        val usernameIds = mutableListOf<AutofillId>()
        val passwordIds = mutableListOf<AutofillId>()
        var webDomain: String? = null

        fun traverseNode(node: AssistStructure.ViewNode) {
            val hints = node.autofillHints ?: emptyArray()
            val afId  = node.autofillId

            if (afId != null) {
                if (hints.any { it.equals("username", true) || it.equals("emailAddress", true) }) {
                    usernameIds += afId
                } else if (hints.any { it.equals("password", true) || it.equals("currentPassword", true) }) {
                    passwordIds += afId
                } else {
                    // Fallback: infer from hint text / input type
                    val inputType = node.inputType
                    val hint = node.hint?.lowercase() ?: ""
                    val isPassword = (inputType and android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD) != 0
                        || (inputType and android.text.InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD) != 0
                        || hint.contains("password") || hint.contains("كلمة")
                    val isUsername = hint.contains("user") || hint.contains("email")
                        || hint.contains("اسم") || hint.contains("بريد")
                    when {
                        isPassword -> passwordIds += afId
                        isUsername -> usernameIds += afId
                    }
                }
            }

            if (webDomain == null) {
                webDomain = node.webDomain
            }

            for (i in 0 until node.childCount) {
                traverseNode(node.getChildAt(i))
            }
        }

        for (i in 0 until structure.windowNodeCount) {
            traverseNode(structure.getWindowNodeAt(i).rootViewNode)
        }

        return ParsedStructure(usernameIds, passwordIds, webDomain)
    }

    // ── Dataset builder ─────────────────────────────────────────────────────

    private fun buildDataset(cred: Credential, parsed: ParsedStructure): Dataset? {
        val label    = cred.title.ifBlank { cred.username }
        val username = cred.username
        val password = cred.password

        if (username.isBlank() && password.isBlank()) return null

        val presentation = RemoteViews(packageName, R.layout.autofill_list_item).apply {
            setTextViewText(R.id.autofill_item_title,    label)
            setTextViewText(R.id.autofill_item_username, username.ifBlank { "—" })
        }

        val builder = Dataset.Builder(presentation)

        for (id in parsed.usernameIds) {
            builder.setValue(id, AutofillValue.forText(username), presentation)
        }
        for (id in parsed.passwordIds) {
            builder.setValue(id, AutofillValue.forText(password), presentation)
        }

        return builder.build()
    }

    // ── Credential cache ────────────────────────────────────────────────────

    private data class Credential(
        val id: String,
        val title: String,
        val username: String,
        val password: String,
        val url: String,
    )

    private fun loadCachedCredentials(): List<Credential> {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val json  = prefs.getString(KEY_CACHE, null) ?: return emptyList()
        return try {
            val arr  = JSONArray(json)
            val list = mutableListOf<Credential>()
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                list += Credential(
                    id       = obj.optString("id"),
                    title    = obj.optString("title"),
                    username = obj.optString("username"),
                    password = obj.optString("password"),
                    url      = obj.optString("url"),
                )
            }
            list
        } catch (_: Exception) {
            emptyList()
        }
    }
}
