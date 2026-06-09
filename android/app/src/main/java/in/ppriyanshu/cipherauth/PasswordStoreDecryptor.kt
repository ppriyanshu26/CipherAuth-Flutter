package `in`.ppriyanshu.cipherauth

import android.util.Base64
import java.security.MessageDigest
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

object PasswordStoreDecryptor {
    fun decryptStore(encryptedData: String, masterPassword: String): String {
        val decoded = Base64.decode(encryptedData, Base64.URL_SAFE or Base64.NO_WRAP)
        
        if (decoded.size < 28) {
            throw IllegalArgumentException("Invalid encrypted store size.")
        }
        
        val nonce = decoded.sliceArray(0 until 12)
        val cipherTextWithMac = decoded.sliceArray(12 until decoded.size)
        
        val digest = MessageDigest.getInstance("SHA-256")
        val keyBytes = digest.digest(masterPassword.toByteArray(Charsets.UTF_8))
        val secretKey = SecretKeySpec(keyBytes, "AES")
        
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val spec = GCMParameterSpec(128, nonce) 
        cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)
        
        val decryptedBytes = cipher.doFinal(cipherTextWithMac)
        return String(decryptedBytes, Charsets.UTF_8)
    }
}
