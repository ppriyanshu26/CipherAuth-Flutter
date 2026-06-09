package `in`.ppriyanshu.cipherauth

object DomainUtils {
    fun extractDomainTld(inputUrl: String?): String {
        if (inputUrl.isNullOrEmpty()) return ""
        
        var cleanUrl = inputUrl.trim().lowercase()
        
        if (cleanUrl.contains("://")) {
            cleanUrl = cleanUrl.substring(cleanUrl.indexOf("://")+3)
        }
        
        val pathSplit = cleanUrl.split('/')
        var host = pathSplit[0]
        
        if (host.contains(':')) {
            host = host.split(':')[0]
        }
        
        if (host.contains('@')) {
            host = host.split('@').last()
        }
        
        host = host.trim()
        if (host.isEmpty()) return ""
        
        val ipv4Regex = Regex("""^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$""")
        if (ipv4Regex.matches(host)) {
            return host
        }
        
        val parts = host.split('.')
        val n = parts.size
        if (n < 2) return host 
        
        val commonSlds = setOf("co", "com", "org", "net", "gov", "edu", "ac")
        
        if (n >= 3) {
            val secondToLast = parts[n-2]
            val last = parts[n-1]
            if (last.length == 2 && commonSlds.contains(secondToLast)) {
                return "${parts[n-3]}.${secondToLast}.${last}"
            }
        }
        return "${parts[n-2]}.${parts[n-1]}"
    }

    fun matchesPackageOrDomain(credentialDomain: String, targetDomain: String, targetPackage: String): Boolean {
        if (targetDomain.isNotEmpty()) {
            val credTld = extractDomainTld(credentialDomain)
            val targetTld = extractDomainTld(targetDomain)
            if (credTld.isNotEmpty() && targetTld.isNotEmpty() && credTld == targetTld) {
                return true
            }
        }
        
        if (targetPackage.isNotEmpty()) {
            val credTld = extractDomainTld(credentialDomain)
            if (credTld.isNotEmpty()) {
                val domainParts = credTld.split('.')
                val mainDomainName = domainParts[0] 
                
                if (mainDomainName.length >= 3) { 
                    val packageParts = targetPackage.lowercase().split('.')
                    for (part in packageParts) {
                        if (part == mainDomainName) {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
}
