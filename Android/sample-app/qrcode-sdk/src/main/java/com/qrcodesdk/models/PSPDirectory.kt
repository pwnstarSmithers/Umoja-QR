package com.qrcodesdk.models

/**
 * PSP Directory Management for Kenya and Tanzania
 */
class PSPDirectory private constructor() {
    
    private val kenyaBanks = mutableMapOf<String, PSPInfo>()
    private val kenyaTelecoms = mutableMapOf<String, PSPInfo>()
    private val tanzaniaProviders = mutableMapOf<String, PSPInfo>()
    
    init {
        loadKenyaBanks()
        loadKenyaTelecoms()
        loadTanzaniaProviders()
    }
    
    companion object {
        @Volatile
        private var INSTANCE: PSPDirectory? = null
        
        fun getInstance(): PSPDirectory {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: PSPDirectory().also { INSTANCE = it }
            }
        }
    }
    
    // MARK: - Public API
    
    /**
     * Get PSP information by GUID and country
     */
    fun getPSP(guid: String, country: Country, type: PSPInfo.PSPType? = null): PSPInfo? {
        return when (country) {
            Country.KENYA -> kenyaBanks[guid] ?: kenyaTelecoms[guid]
            Country.TANZANIA -> tanzaniaProviders[guid]
        }
    }
    
    /**
     * Get PSP information by tag and nested content
     */
    fun parsePSPFromTemplate(tag: String, nestedFields: List<TLVField>, country: Country): PSPInfo? {
        return when (tag) {
            "26" -> parseTanzaniaTemplate(nestedFields)
            "28" -> parseKenyaTelecomTemplate(nestedFields)
            "29" -> parseKenyaBankTemplate(nestedFields)
            else -> null
        }
    }
    
    /**
     * Get all PSPs for a country
     */
    fun getAllPSPs(country: Country): List<PSPInfo> {
        return when (country) {
            Country.KENYA -> kenyaBanks.values.toList() + kenyaTelecoms.values.toList()
            Country.TANZANIA -> tanzaniaProviders.values.toList()
        }
    }
    
    /**
     * Check if a PSP is supported
     */
    fun isSupported(guid: String, country: Country): Boolean {
        return getPSP(guid, country) != null
    }
    
    /**
     * Update PSP directory (for dynamic updates)
     */
    fun updatePSP(psp: PSPInfo, guid: String) {
        when (psp.country to psp.type) {
            Country.KENYA to PSPInfo.PSPType.BANK -> kenyaBanks[guid] = psp
            Country.KENYA to PSPInfo.PSPType.TELECOM -> kenyaTelecoms[guid] = psp
            Country.TANZANIA to PSPInfo.PSPType.BANK,
            Country.TANZANIA to PSPInfo.PSPType.TELECOM,
            Country.TANZANIA to PSPInfo.PSPType.UNIFIED -> tanzaniaProviders[guid] = psp
        }
    }
    
    // MARK: - Kenya Bank PSPs (Tag 29)
    
    private fun loadKenyaBanks() {
        // Add standard CBK GUID
        kenyaBanks["ke.go.qr"] = PSPInfo(
            type = PSPInfo.PSPType.BANK,
            identifier = "CBK",
            name = "Central Bank of Kenya (CBK) - Standard QR",
            country = Country.KENYA
        )
        
        val banks = listOf(
            Triple("EQLT", "68", "Equity Bank Kenya Ltd"),
            Triple("KCBL", "01", "KCB Bank Kenya Limited"),
            Triple("SCBK", "02", "Standard Chartered Bank Kenya Ltd"),
            Triple("ABSA", "03", "ABSA Bank Kenya PLC"),
            Triple("BOIN", "05", "Bank of India"),
            Triple("BOBK", "06", "Bank of Baroda (Kenya) Ltd"),
            Triple("NCBA", "07", "NCBA Kenya PLC"),
            Triple("PRIM", "10", "Prime Bank Ltd"),
            Triple("COOP", "11", "Co-operative Bank of Kenya Ltd"),
            Triple("NATL", "12", "National Bank of Kenya Ltd"),
            Triple("MORI", "14", "M-Oriental Bank Limited"),
            Triple("CITI", "16", "Citibank N.A. Kenya"),
            Triple("HABB", "17", "Habib Bank AG Zurich"),
            Triple("MIDB", "18", "Middle East Bank Kenya Ltd"),
            Triple("BOAF", "19", "Bank of Africa Kenya Ltd"),
            Triple("CONS", "23", "Consolidated Bank of Kenya Ltd"),
            Triple("CRED", "25", "Credit Bank Ltd"),
            Triple("ACCE", "26", "Access Bank (Kenya) Ltd"),
            Triple("CHAS", "30", "Chase Bank (K) Ltd"),
            Triple("STAN", "31", "Stanbic Bank Kenya Ltd"),
            Triple("AFBC", "35", "African Banking Corporation Ltd"),
            Triple("IMPE", "39", "Imperial Bank Ltd"),
            Triple("ECOB", "43", "Ecobank Kenya Ltd"),
            Triple("SPIR", "49", "Spire Bank Ltd"),
            Triple("PARA", "50", "Paramount Bank Ltd"),
            Triple("KING", "51", "Kingdom Bank Ltd"),
            Triple("GUAR", "53", "Guaranty Trust Bank (Kenya) Ltd"),
            Triple("VICT", "54", "Victoria Commercial Bank Ltd"),
            Triple("GUAR", "55", "Guardian Bank Ltd"),
            Triple("IMBA", "57", "I&M Bank Ltd"),
            Triple("DEVB", "59", "Development Bank of Kenya Ltd"),
            Triple("SBMB", "60", "SBM Bank (Kenya) Ltd"),
            Triple("DIAM", "63", "Diamond Trust Bank (K) Ltd"),
            Triple("CHAR", "64", "Charterhouse Bank Ltd"),
            Triple("MAYF", "65", "Mayfair CIB Bank Ltd"),
            Triple("SIDI", "66", "Sidian Bank Ltd"),
            Triple("FAMI", "70", "Family Bank Ltd"),
            Triple("GULF", "72", "Gulf African Bank Ltd"),
            Triple("FIRST", "74", "First Community Bank Ltd"),
            Triple("DIBB", "75", "DIB Bank Kenya Ltd"),
            Triple("UBAK", "76", "UBA Kenya Bank Ltd"),
            Triple("HFCL", "83", "HFC Limited")
        )
        
        banks.forEach { (guid, identifier, name) ->
            kenyaBanks[guid] = PSPInfo(
                type = PSPInfo.PSPType.BANK,
                identifier = identifier,
                name = name,
                country = Country.KENYA
            )
        }
    }
    
    // MARK: - Kenya Telecom PSPs (Tag 28)
    
    private fun loadKenyaTelecoms() {
        val telecoms = listOf(
            Triple("MPESA", "01", "Safaricom (M-PESA)"),
            Triple("AIRTL", "02", "Airtel Money"),
            Triple("TKOM", "03", "Telkom Kenya T-Kash"),
            Triple("PESP", "12", "PesaPal")
        )
        
        telecoms.forEach { (guid, identifier, name) ->
            kenyaTelecoms[guid] = PSPInfo(
                type = PSPInfo.PSPType.TELECOM,
                identifier = identifier,
                name = name,
                country = Country.KENYA
            )
        }
    }
    
    // MARK: - Tanzania Providers (Tag 26 - TIPS)
    
    private fun loadTanzaniaProviders() {
        val providers = listOf(
            "01001" to "CRDB Bank PLC",
            "01002" to "National Bank of Commerce (NBC)",
            "01003" to "NMB Bank PLC",
            "01004" to "Stanbic Bank Tanzania Ltd",
            "01005" to "Equity Bank (Tanzania) Ltd",
            "01006" to "ABSA Bank Tanzania Ltd",
            "01007" to "Standard Chartered Bank Tanzania Ltd",
            "01008" to "Exim Bank (T) Ltd",
            "01009" to "Bank of Africa Tanzania Ltd",
            "01010" to "Access Bank Tanzania Ltd",
            "02001" to "Vodacom M-Pesa",
            "02002" to "Tigo Pesa",
            "02003" to "Airtel Money",
            "02004" to "Azam Pay",
            "02005" to "PesaPal Tanzania"
        )
        
        providers.forEach { (acquirerId, name) ->
            val type = if (acquirerId.startsWith("01")) PSPInfo.PSPType.BANK else PSPInfo.PSPType.TELECOM
            tanzaniaProviders[acquirerId] = PSPInfo(
                type = type,
                identifier = acquirerId,
                name = name,
                country = Country.TANZANIA
            )
        }
    }
    
    // MARK: - Template Parsing
    
    private fun parseTanzaniaTemplate(nestedFields: List<TLVField>): PSPInfo? {
        val guidField = nestedFields.firstOrNull { it.tag == "00" }
        val acquirerField = nestedFields.firstOrNull { it.tag == "01" }
        
        return if (guidField?.value == "tz.go.bot.tips" && acquirerField != null) {
            tanzaniaProviders[acquirerField.value]
        } else null
    }
    
    private fun parseKenyaBankTemplate(nestedFields: List<TLVField>): PSPInfo? {
        val guidField = nestedFields.firstOrNull { it.tag == "00" }
        return guidField?.let { kenyaBanks[it.value] }
    }
    
    private fun parseKenyaTelecomTemplate(nestedFields: List<TLVField>): PSPInfo? {
        // For Kenya telecoms, we may have direct identifier or GUID
        val guidField = nestedFields.firstOrNull { it.tag == "00" }
        if (guidField != null) {
            return kenyaTelecoms[guidField.value]
        }
        
        // Fallback: try to identify by pattern or subtag
        val identifierField = nestedFields.firstOrNull { it.tag == "01" }
        return identifierField?.let { field ->
            when (field.value) {
                "01" -> kenyaTelecoms["MPESA"]
                "02" -> kenyaTelecoms["AIRTL"]
                "03" -> kenyaTelecoms["TKOM"]
                "12" -> kenyaTelecoms["PESP"]
                else -> null
            }
        }
    }
}

// MARK: - Template Builder Helper

object AccountTemplateBuilder {
    
    /**
     * Build account template for Kenya bank
     */
    fun kenyaBank(guid: String, accountNumber: String): AccountTemplate? {
        val pspInfo = PSPDirectory.getInstance().getPSP(guid, Country.KENYA, PSPInfo.PSPType.BANK)
            ?: return null
        
        return AccountTemplate(
            tag = "29",
            guid = guid,
            participantId = pspInfo.identifier,
            accountId = accountNumber,
            pspInfo = pspInfo
        )
    }
    
    /**
     * Build account template for Kenya telecom
     */
    fun kenyaTelecom(guid: String, phoneNumber: String): AccountTemplate? {
        val pspInfo = PSPDirectory.getInstance().getPSP(guid, Country.KENYA, PSPInfo.PSPType.TELECOM)
            ?: return null
        
        return AccountTemplate(
            tag = "28",
            guid = guid,
            participantId = pspInfo.identifier,
            accountId = phoneNumber,
            pspInfo = pspInfo
        )
    }
    
    /**
     * Build account template for Tanzania (TIPS)
     */
    fun tanzania(acquirerId: String, merchantId: String): AccountTemplate? {
        val pspInfo = PSPDirectory.getInstance().getPSP(acquirerId, Country.TANZANIA) ?: return null
        
        return AccountTemplate(
            tag = "26",
            guid = "tz.go.bot.tips",
            participantId = acquirerId,
            accountId = merchantId,
            pspInfo = pspInfo
        )
    }
} 