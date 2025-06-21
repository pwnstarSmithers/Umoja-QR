import Foundation

// MARK: - PSP Directory Management
// Based on Central Bank of Kenya QR Code Standard 2023
// Official PSP Directory: https://www.centralbank.go.ke/wp-content/uploads/2023/04/QR-Code-Unique-Identifiers-Directory-of-Banks-andAuthorized-Payment-Service-Providers.pdf

/// PSP Directory implementing CBK QR Code Standard 2023
/// Manages Payment Service Provider information for Kenya (KE-QR) and Tanzania (TAN-QR) systems
/// 
/// Key CBK Standard Compliance:
/// - Tag 28: Kenya PSP account identifiers (telecoms/mobile money)
/// - Tag 29: Kenya bank wallet identifiers 
/// - Tag 26: Tanzania unified TAN-QR identifiers
/// - GUID "ke.go.qr": Kenya domestic QR standard identifier
/// - GUID "tz.go.bot.tips": Tanzania TAN-QR system identifier
public class PSPDirectory {
    
    public static let shared = PSPDirectory()
    
    private var kenyaBanks: [String: PSPInfo] = [:]
    private var kenyaTelecoms: [String: PSPInfo] = [:]
    private var tanzaniaProviders: [String: PSPInfo] = [:]
    
    private init() {
        loadKenyaBanks()
        loadKenyaTelecoms()
        loadTanzaniaProviders()
    }
    
    // MARK: - Public API
    
    /// Get PSP information by GUID and country
    public func getPSP(guid: String, country: Country, type: PSPInfo.PSPType? = nil) -> PSPInfo? {
        switch country {
        case .kenya:
            return kenyaBanks[guid] ?? kenyaTelecoms[guid]
        case .tanzania:
            return tanzaniaProviders[guid]
        }
    }
    
    /// Get PSP information by tag and nested content
    public func parsePSPFromTemplate(tag: String, nestedFields: [TLVField], country: Country) -> PSPInfo? {
        switch tag {
        case "26": // Tanzania unified template
            return parseTanzaniaTemplate(nestedFields: nestedFields)
        case "28": // Kenya telecom template
            return parseKenyaTelecomTemplate(nestedFields: nestedFields)
        case "29": // Kenya bank template
            return parseKenyaBankTemplate(nestedFields: nestedFields)
        default:
            return nil
        }
    }
    
    /// Get all PSPs for a country
    public func getAllPSPs(for country: Country) -> [PSPInfo] {
        switch country {
        case .kenya:
            return Array(kenyaBanks.values) + Array(kenyaTelecoms.values)
        case .tanzania:
            return Array(tanzaniaProviders.values)
        }
    }
    
    /// Check if a PSP is supported
    public func isSupported(guid: String, country: Country) -> Bool {
        return getPSP(guid: guid, country: country) != nil
    }
    
    /// Find bank GUID using progressive prefix matching (CBK compliant)
    public func findBankGUID(pspId: String) -> String? {
        // Progressive prefix matching for Kenya banks (7,6,5,4,3,2 characters)
        for length in stride(from: min(pspId.count, 7), through: 2, by: -1) {
            let prefix = String(pspId.prefix(length))
            
            // Search in banks first
            if let bankInfo = kenyaBanks.values.first(where: { $0.identifier.hasPrefix(prefix) || $0.identifier == prefix }) {
                // Return the original GUID that maps to this bank
                if let guid = kenyaBanks.first(where: { $0.value.identifier == bankInfo.identifier })?.key {
                    return guid
                }
            }
        }
        return nil
    }
    
    /// Find telecom GUID using progressive prefix matching
    public func findTelecomGUID(pspId: String) -> String? {
        // Progressive prefix matching for Kenya telecoms
        for length in stride(from: min(pspId.count, 7), through: 2, by: -1) {
            let prefix = String(pspId.prefix(length))
            
            if let telecomInfo = kenyaTelecoms.values.first(where: { $0.identifier.hasPrefix(prefix) || $0.identifier == prefix }) {
                // Return the original GUID that maps to this telecom
                if let guid = kenyaTelecoms.first(where: { $0.value.identifier == telecomInfo.identifier })?.key {
                    return guid
                }
            }
        }
        return nil
    }
    
    /// Lookup PSP by identifier with progressive matching
    public func lookupPSP(byIdentifier identifier: String, country: Country, type: PSPInfo.PSPType? = nil) -> PSPInfo? {
        let allPSPs = getAllPSPs(for: country)
        
        // Filter by type if specified
        let filteredPSPs = type != nil ? allPSPs.filter { $0.type == type } : allPSPs
        
        // Progressive prefix matching (7,6,5,4,3,2 characters)
        for length in stride(from: min(identifier.count, 7), through: 2, by: -1) {
            let prefix = String(identifier.prefix(length))
            
            if let psp = filteredPSPs.first(where: { $0.identifier.hasPrefix(prefix) || $0.identifier == prefix }) {
                return psp
            }
        }
        
        return nil
    }
    
    /// Get PSP information by phone number (for telecom PSPs)
    public func getPSPFromPhoneNumber(_ phoneNumber: String) -> PSPInfo? {
        // Detect PSP from phone number patterns (Kenya)
        let cleanPhone = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // M-PESA patterns: 254712345678, 254707123456, 254701123456
        if cleanPhone.hasPrefix("25471") || cleanPhone.hasPrefix("25470") {
            return kenyaTelecoms["MPSA"]
        }
        
        // Airtel Money patterns: 254731234567, 254734123456
        if cleanPhone.hasPrefix("25473") {
            return kenyaTelecoms["AMNY"]
        }
        
        // Telkom T-Kash patterns: 254771234567
        if cleanPhone.hasPrefix("25477") {
            return kenyaTelecoms["TKSH"]
        }
        
        return nil
    }
    
    /// Update PSP directory (for dynamic updates)
    public func updatePSP(_ psp: PSPInfo, guid: String) {
        switch (psp.country, psp.type) {
        case (.kenya, .bank):
            kenyaBanks[guid] = psp
        case (.kenya, .telecom):
            kenyaTelecoms[guid] = psp
        case (.tanzania, _):
            tanzaniaProviders[guid] = psp
        default:
            break
        }
    }
    
    // MARK: - Kenya Bank PSPs (Tag 29)
    
    private func loadKenyaBanks() {
        kenyaBanks = [
            "EQLT": PSPInfo(type: .bank, identifier: "68", name: "Equity Bank", country: .kenya),
            "KCBK": PSPInfo(type: .bank, identifier: "01", name: "Kenya Commercial Bank", country: .kenya),
            "COOP": PSPInfo(type: .bank, identifier: "11", name: "Co-operative Bank", country: .kenya),
            "SCBL": PSPInfo(type: .bank, identifier: "03", name: "Standard Chartered Bank", country: .kenya),
            "ABSA": PSPInfo(type: .bank, identifier: "04", name: "ABSA Bank Kenya", country: .kenya),
            "DTBK": PSPInfo(type: .bank, identifier: "49", name: "Diamond Trust Bank", country: .kenya),
            "SBIC": PSPInfo(type: .bank, identifier: "02", name: "Stanbic Bank", country: .kenya),
            "NCBA": PSPInfo(type: .bank, identifier: "07", name: "NCBA Group", country: .kenya)
        ]
    }
    
    // MARK: - Kenya Telecom PSPs (Tag 28)
    
    private func loadKenyaTelecoms() {
        // Kenya Telecoms - Updated names for CBK compliance
        kenyaTelecoms = [
            "MPSA": PSPInfo(type: .telecom, identifier: "01", name: "Safaricom M-PESA", country: .kenya),
            "AMNY": PSPInfo(type: .telecom, identifier: "02", name: "Airtel Money", country: .kenya),
            "TKSH": PSPInfo(type: .telecom, identifier: "03", name: "Telkom T-Kash", country: .kenya),
            "MTAP": PSPInfo(type: .telecom, identifier: "04", name: "MobiTap", country: .kenya)
        ]
    }
    
    // MARK: - Tanzania Providers (Tag 26 - TAN-QR)
    
    private func loadTanzaniaProviders() {
        // Tanzania uses TIPS (Tanzania Instant Payment System) with TANQR standard
        // All providers use "tz.go.bot.tips" as GUID in Tag 26
        // Actual provider identification is via 5-digit Acquirer ID format
        
        // Official TANQR Acquirer IDs as per Bank of Tanzania standard
        let providers = [
            // Banks (Category 01 + 3-digit participant codes)
            ("01032", "ABSA Bank Tanzania Limited"),
            ("01010", "Akiba Commercial Bank"),
            ("01036", "Amana Bank"),
            ("01028", "Azania Bank"),
            ("01041", "Bank of Baroda"),
            ("01030", "Bank of Africa"),
            ("01020", "Bank of Tanzania"),
            ("01040", "Canara Bank"),
            ("01034", "NCBA Bank"),
            ("01038", "Citi Bank"),
            ("01007", "CRDB Bank"),
            ("01022", "DCB Commercial Bank"),
            ("01026", "Diamond Trust Bank"),
            ("01024", "Ecobank"),
            ("01037", "Equity Bank"),
            ("01023", "Exim Bank"),
            ("01035", "Guaranty Trust Bank"),
            ("01033", "Habib Bank"),
            ("01039", "I&M Bank (Tanzania) Ltd"),
            ("01031", "KCB Bank"),
            ("01008", "National Bank of Commerce"),
            ("01006", "National Microfinance Bank (NMB)"),
            ("01019", "Peoples Bank of Zanzibar"),
            ("01027", "Standard Chartered Bank"),
            ("01025", "Stanbic Bank"),
            ("01021", "Tanzania Investment Bank"),
            ("01009", "Tanzania Postal Bank"),
            ("01029", "United Bank for Africa (Tanzania)"),
            
            // Non-Bank Financial Institutions (Category 02 + 3-digit codes)
            ("02101", "Vodacom M-Pesa Tanzania"),
            ("02102", "Tigo Pesa"),
            ("02103", "Airtel Money Tanzania"),
            ("02104", "Azam Pay"),
            ("02105", "PesaPal Tanzania")
        ]
        
        for (acquirerId, name) in providers {
            // Banks start with "01", Non-banks start with "02"
            let type: PSPInfo.PSPType = acquirerId.hasPrefix("01") ? .bank : .telecom
            tanzaniaProviders[acquirerId] = PSPInfo(
                type: type,
                identifier: acquirerId,
                name: name,
                country: .tanzania
            )
        }
    }
    
    // MARK: - Template Parsing
    
    private func parseTanzaniaTemplate(nestedFields: [TLVField]) -> PSPInfo? {
        guard let guidField = nestedFields.first(where: { $0.tag == "00" }),
              guidField.value == "tz.go.bot.tips",
              let acquirerField = nestedFields.first(where: { $0.tag == "01" }) else {
            return nil
        }
        
        // Look up PSP using 5-digit Acquirer ID (TANQR standard)
        let acquirerId = acquirerField.value
        
        // Validate Acquirer ID format (should be 5 digits)
        guard acquirerId.count == 5 && acquirerId.allSatisfy({ $0.isNumber }) else {
            return nil
        }
        
        return tanzaniaProviders[acquirerId]
    }
    
    private func parseKenyaBankTemplate(nestedFields: [TLVField]) -> PSPInfo? {
        guard let guidField = nestedFields.first(where: { $0.tag == "00" }) else {
            print("🚨 parseKenyaBankTemplate: No GUID field found")
            return nil
        }
        
        print("🔍 parseKenyaBankTemplate: GUID = '\(guidField.value)'")
        
        // Handle CBK standard domestic format: ke.go.qr
        if guidField.value == "ke.go.qr" {
            print("🔍 parseKenyaBankTemplate: Processing CBK domestic format")
            // Parse CBK domestic format - PSP identifier should be in sub-field
            // P2P uses Tag 68 (account identifier), P2M uses Tag 07 (merchant identifier)
            var pspField: TLVField?
            var fieldType = "unknown"
            
            if let accountField = nestedFields.first(where: { $0.tag == "68" }) {
                pspField = accountField
                fieldType = "P2P account (Tag 68)"
            } else if let merchantField = nestedFields.first(where: { $0.tag == "07" }) {
                pspField = merchantField
                fieldType = "P2M merchant (Tag 07)"
            }
            
            if let pspField = pspField {
                // Map PSP identifier to GUID for lookup
                let pspId = pspField.value
                print("🔍 parseKenyaBankTemplate: PSP ID = '\(pspId)' from \(fieldType)")
                // Map numeric PSP ID to bank GUID (based on CBK directory)
                if let bankGuid = mapPSPIdToBankGuid(pspId) {
                    print("🔍 parseKenyaBankTemplate: Mapped to GUID = '\(bankGuid)'")
                    let result = kenyaBanks[bankGuid]
                    print("🔍 parseKenyaBankTemplate: Lookup result = \(result?.name ?? "nil")")
                    return result
                }
                print("🚨 parseKenyaBankTemplate: PSP ID mapping failed")
                // If not found in mapping, check if it's a direct 2-character bank code
                let fallbackResult = kenyaBanks.values.first { $0.identifier == pspId.prefix(2) }
                print("🔍 parseKenyaBankTemplate: Fallback result = \(fallbackResult?.name ?? "nil")")
                return fallbackResult
            } else {
                print("🚨 parseKenyaBankTemplate: No Tag 68 (P2P) or Tag 07 (P2M) found in CBK format")
                
                // Check if this is a Safaricom secondary identifier case
                // Sometimes Safaricom QR codes include Tag 29 as a placeholder/secondary identifier
                // but the actual PSP information is in Tag 28 (telecom template)
                if nestedFields.count == 1 && nestedFields[0].tag == "00" && nestedFields[0].value == "ke.go.qr" {
                    print("⚠️ parseKenyaBankTemplate: Detected placeholder Tag 29 with only ke.go.qr GUID")
                    print("⚠️ parseKenyaBankTemplate: This appears to be a Safaricom secondary identifier - skipping")
                    return nil // Return nil to indicate this template should be skipped
                }
            }
            return nil
        }
        
        // Handle legacy direct GUID lookup
        print("🔍 parseKenyaBankTemplate: Using legacy GUID lookup")
        let result = kenyaBanks[guidField.value]
        print("🔍 parseKenyaBankTemplate: Legacy result = \(result?.name ?? "nil")")
        return result
    }
    
    private func parseKenyaTelecomTemplate(nestedFields: [TLVField]) -> PSPInfo? {
        guard let guidField = nestedFields.first(where: { $0.tag == "00" }) else {
            return nil
        }
        
        print("🔍 parseKenyaTelecomTemplate: GUID = '\(guidField.value)'")
        
        // Handle CBK standard domestic format: ke.go.qr
        if guidField.value == "ke.go.qr" {
            print("🔍 parseKenyaTelecomTemplate: Processing CBK domestic format")
            
            // First, check if there's a Tag 68 with explicit PSP identifier
            if let pspField = nestedFields.first(where: { $0.tag == "68" }) {
                print("🔍 parseKenyaTelecomTemplate: Found Tag 68 with PSP ID: \(pspField.value)")
                let pspId = pspField.value
                // Map numeric PSP ID to telecom GUID
                if let telecomGuid = mapPSPIdToTelecomGuid(pspId) {
                    print("✅ parseKenyaTelecomTemplate: Mapped PSP ID to GUID: \(telecomGuid)")
                    return kenyaTelecoms[telecomGuid]
                }
                return kenyaTelecoms.values.first { $0.identifier == pspId.prefix(2) }
            }
            
            // Safaricom-specific format: ke.go.qr in Tag 00, phone number in Tag 01, no explicit PSP ID
            // This is a common format used by Safaricom M-PESA QR codes
            if let phoneField = nestedFields.first(where: { $0.tag == "01" }) {
                let phoneNumber = phoneField.value
                print("🔍 parseKenyaTelecomTemplate: Found Tag 01 with phone number: \(phoneNumber)")
                
                // Handle both local (7xxxxxxxx) and international (254xxxxxxxxx) formats
                if phoneNumber.count >= 9 {
                    // Check for Kenyan phone number patterns
                    if phoneNumber.hasPrefix("254") && phoneNumber.count >= 12 {
                        // International format: 254xxxxxxxxx
                        let localPart = String(phoneNumber.dropFirst(3)) // Remove '254'
                        if localPart.first == "7" {
                            print("✅ parseKenyaTelecomTemplate: Detected Safaricom M-PESA (international format 254)")
                            return kenyaTelecoms["MPSA"]
                        }
                    } else if phoneNumber.first == "7" {
                        // Local format: 7xxxxxxxx
                        print("✅ parseKenyaTelecomTemplate: Detected Safaricom M-PESA (local format)")
                        return kenyaTelecoms["MPSA"]
                    }
                }
                
                // Additional fallback for other telecom patterns
                // Airtel Kenya also uses 7xx numbers, but we'll default to M-PESA for CBK domestic format
                if phoneNumber.contains("7") {
                    print("✅ parseKenyaTelecomTemplate: Contains '7' - defaulting to M-PESA for ke.go.qr format")
                    return kenyaTelecoms["MPSA"]
                }
            }
            
            // Final fallback: check for M-PESA domain in extension fields (Tag 83)
            // This is specific to Safaricom's implementation which may use extension fields
            print("🔍 parseKenyaTelecomTemplate: Checking extension fields for M-PESA identifiers...")
            // Note: Extension fields (Tags 80-99) are not part of the nested template parsing
            // They would be at the top level, so we can't access them here
            // This is handled in the main parser for CBK domestic QR codes
            
            print("🚨 parseKenyaTelecomTemplate: No Tag 68 or valid Tag 01 found in CBK format")
            return nil
        }
        
        // Handle legacy formats
        if let telecomPSP = kenyaTelecoms[guidField.value] {
            return telecomPSP
        }
        
        // Fallback: try to identify by pattern or subtag
        if let identifierField = nestedFields.first(where: { $0.tag == "01" }) {
            // Map identifier to GUID
            switch identifierField.value {
            case "01": return kenyaTelecoms["MPSA"]
            case "02": return kenyaTelecoms["AMNY"]
            case "03": return kenyaTelecoms["TKSH"]
            case "12": return kenyaTelecoms["PESP"]
            default: return nil
            }
        }
        
        return nil
    }
    
    // MARK: - CBK Standard PSP ID Mapping
    
    /// Map CBK numeric PSP ID to bank GUID for lookup
    private func mapPSPIdToBankGuid(_ pspId: String) -> String? {
        // This maps the actual PSP identifiers from the CBK directory
        let pspIdToBankMap: [String: String] = [
            // Map PSP ID patterns to bank GUID
            "22266": "EQLT",     // Equity Bank (matches QR pattern 2226665)
            "2226665": "EQLT",   // Equity Bank full ID
            "22266655": "EQLT",  // Equity Bank P2M merchant ID pattern
            "01": "KCBK",      // KCB
            "02": "SBIC",      // Standard Chartered
            "03": "ABSA",      // ABSA
            "04": "ABSA",      // ABSA
            "05": "BOIN",      // Bank of India
            "06": "BOBK",      // Bank of Baroda
            "07": "NCBA",      // NCBA
            "10": "PRIM",      // Prime Bank
            "11": "COOP",      // Co-operative Bank
            "12": "NATL",      // National Bank
            "14": "MORI",      // M-Oriental Bank
            "16": "CITI",      // Citibank
            "17": "HABB",      // Habib Bank
            "18": "MIDB",      // Middle East Bank
            "19": "BOAF",      // Bank of Africa
            "23": "CONS",      // Consolidated Bank
            "25": "CRED",      // Credit Bank
            "26": "ACCE",      // Access Bank
            "30": "CHAS",      // Chase Bank
            "31": "STAN",      // Stanbic Bank
            "35": "AFBC",      // African Banking Corporation
            "39": "IMPE",      // Imperial Bank
            "43": "ECOB",      // Ecobank
            "49": "DTBK",      // Diamond Trust Bank
            "50": "PARA",      // Paramount Bank
            "51": "KING",      // Kingdom Bank
            "53": "GUAR",      // Guaranty Trust Bank
            "54": "VICT",      // Victoria Commercial Bank
            "55": "GUAR",      // Guardian Bank
            "57": "IMBA",      // I&M Bank
            "59": "DEVB",      // Development Bank
            "60": "SBMB",      // SBM Bank
            "63": "DIAM",      // Diamond Trust Bank
            "64": "CHAR",      // Charterhouse Bank
            "65": "MAYF",      // Mayfair CIB Bank
            "66": "SIDI",      // Sidian Bank
            "68": "EQLT",      // Equity Bank (additional mapping)
            "70": "FAMI",      // Family Bank
            "72": "GULF",      // Gulf African Bank
            "74": "FIRST",     // First Community Bank
            "75": "DIBB",      // DIB Bank
            "76": "UBAK",      // UBA Kenya Bank
            "83": "HFCL"       // HFC Limited
        ]
        
        // Try exact match first, then progressively shorter prefixes
        let prefixLengths = [pspId.count, 7, 6, 5, 4, 3, 2]
        
        for length in prefixLengths {
            if pspId.count >= length {
                let prefix = String(pspId.prefix(length))
                if let guid = pspIdToBankMap[prefix] {
                    return guid
                }
            }
        }
        
        return nil
    }
    
    /// Map CBK numeric PSP ID to telecom GUID for lookup
    private func mapPSPIdToTelecomGuid(_ pspId: String) -> String? {
        let pspIdToTelecomMap: [String: String] = [
            "01": "MPSA",     // Safaricom M-PESA
            "02": "AMNY",     // Airtel Money
            "03": "TKSH",      // Telkom T-Kash
            "12": "PESP"       // PesaPal
        ]
        
        // Try full PSP ID first, then first 2 characters
        if let guid = pspIdToTelecomMap[pspId] {
            return guid
        }
        if pspId.count >= 2, let guid = pspIdToTelecomMap[String(pspId.prefix(2))] {
            return guid
        }
        
        return nil
    }
    
    // MARK: - CBK Compliance Methods
    
    /// Lookup PSP by ID and type (for CBK compliance tests)
    public func lookupPSP(id: String, type: PSPInfo.PSPType, country: Country) -> PSPInfo? {
        let allPSPs = getAllPSPs(for: country)
        return allPSPs.first { $0.identifier == id && $0.type == type }
    }
    
    /// Get PSP by ID with progressive prefix matching (CBK compliant)
    public func getPSPByID(_ pspId: String, country: Country) -> PSPInfo? {
        let allPSPs = getAllPSPs(for: country)
        
        // First try exact match
        if let exactMatch = allPSPs.first(where: { $0.identifier == pspId }) {
            return exactMatch
        }
        
        // Then try progressive prefix matching (7,6,5,4,3,2 characters)
        for length in stride(from: min(pspId.count, 7), through: 2, by: -1) {
            let prefix = String(pspId.prefix(length))
            if let match = allPSPs.first(where: { $0.identifier == prefix }) {
                return match
            }
        }
        
        return nil
    }
}

// MARK: - PSP Directory Extensions

extension PSPInfo {
    
    /// Create a PSP info from GUID lookup
    public static func fromGUID(_ guid: String, country: Country) -> PSPInfo? {
        return PSPDirectory.shared.getPSP(guid: guid, country: country)
    }
    
    /// Check if this PSP supports multi-currency
    public var supportsMultiCurrency: Bool {
        switch (country, type) {
        case (.kenya, .bank): return true  // Most Kenyan banks support multi-currency
        case (.tanzania, .bank): return true
        default: return false  // Mobile money typically single currency
        }
    }
    
    /// Get the appropriate template tag for this PSP
    public var templateTag: String {
        switch (country, type) {
        case (.kenya, .bank): return "29"
        case (.kenya, .telecom), (.kenya, .paymentGateway): return "28"
        case (.kenya, .unified): return "28" // Fallback for unified in Kenya
        case (.tanzania, _): return "26"
        }
    }
}

// MARK: - Template Builder Helper

public struct AccountTemplateBuilder {
    
    /// Build CBK-compliant account template for Kenya bank
    public static func kenyaBank(guid: String, accountNumber: String) -> AccountTemplate? {
        guard let pspInfo = PSPDirectory.shared.getPSP(guid: guid, country: .kenya, type: .bank) else {
            return nil
        }
        
        return AccountTemplate(
            tag: "29",
            guid: "ke.go.qr",  // CBK domestic identifier
            participantId: pspInfo.identifier,  // PSP ID (e.g., "68" for Equity)
            accountId: accountNumber,
            pspInfo: pspInfo
        )
    }
    
    /// Build CBK-compliant account template for Kenya telecom
    public static func kenyaTelecom(guid: String, phoneNumber: String) -> AccountTemplate? {
        guard let pspInfo = PSPDirectory.shared.getPSP(guid: guid, country: .kenya, type: .telecom) else {
            return nil
        }
        
        return AccountTemplate(
            tag: "28",
            guid: "ke.go.qr",  // CBK domestic identifier
            participantId: pspInfo.identifier,  // PSP ID (e.g., "01" for M-PESA)
            accountId: phoneNumber,
            pspInfo: pspInfo
        )
    }
    
    /// Build account template for Tanzania (TANQR)
    public static func tanzania(acquirerId: String, merchantId: String) -> AccountTemplate? {
        guard let pspInfo = PSPDirectory.shared.getPSP(guid: acquirerId, country: .tanzania) else {
            return nil
        }
        
        return AccountTemplate(
            tag: "26",
            guid: "tz.go.bot.tips",
            participantId: acquirerId,
            accountId: merchantId,
            pspInfo: pspInfo
        )
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    
    /// Build legacy account template for Kenya bank (non-CBK format)
    public static func kenyaBankLegacy(guid: String, accountNumber: String) -> AccountTemplate? {
        guard let pspInfo = PSPDirectory.shared.getPSP(guid: guid, country: .kenya, type: .bank) else {
            return nil
        }
        
        return AccountTemplate(
            tag: "29",
            guid: guid,  // Use PSP-specific GUID (e.g., "EQLT")
            participantId: pspInfo.identifier,
            accountId: accountNumber,
            pspInfo: pspInfo
        )
    }
    
    /// Build legacy account template for Kenya telecom (non-CBK format)
    public static func kenyaTelecomLegacy(guid: String, phoneNumber: String) -> AccountTemplate? {
        guard let pspInfo = PSPDirectory.shared.getPSP(guid: guid, country: .kenya, type: .telecom) else {
            return nil
        }
        
        return AccountTemplate(
            tag: "28",
            guid: guid,  // Use PSP-specific GUID (e.g., "MPSA")
            participantId: pspInfo.identifier,
            accountId: phoneNumber,
            pspInfo: pspInfo
        )
    }
} 