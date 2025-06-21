import Foundation

// MARK: - Merchant Category Code Management

public class MerchantCategories {
    
    public static let shared = MerchantCategories()
    
    private init() {}
    
    // MARK: - P2P MCCs (Financial Services)
    
    /// MCCs that indicate P2P (person-to-person) transactions
    public static let p2pMCCs: Set<String> = [
        "6011", // Financial Institutions - Automated Cash Disbursements
        "6012", // Financial Institutions - Merchandise and Services
        "6051", // Quasi Cash - Financial Institutions
        "6211", // Securities Brokers/Dealers
        "6540"  // Non-financial Institution - POI Funding
    ]
    
    // MARK: - Common Merchant Categories
    
    /// Common merchant categories with descriptions
    public static let merchantCategories: [String: MerchantCategory] = [
        // Retail
        "5311": MerchantCategory("Department Stores", .retail),
        "5411": MerchantCategory("Grocery Stores, Supermarkets", .retail),
        "5422": MerchantCategory("Freezer and Locker Meat Provisioners", .retail),
        "5441": MerchantCategory("Candy, Nut, and Confectionery Stores", .retail),
        "5451": MerchantCategory("Dairy Products Stores", .retail),
        "5462": MerchantCategory("Bakeries", .retail),
        "5499": MerchantCategory("Miscellaneous Food Stores", .retail),
        "5511": MerchantCategory("Car and Truck Dealers", .automotive),
        "5541": MerchantCategory("Service Stations", .automotive),
        "5542": MerchantCategory("Automated Fuel Dispensers", .automotive),
        "5611": MerchantCategory("Men's and Boys' Clothing", .retail),
        "5621": MerchantCategory("Women's Ready-to-Wear Stores", .retail),
        "5631": MerchantCategory("Women's Accessory Stores", .retail),
        "5641": MerchantCategory("Children's and Infants' Wear Stores", .retail),
        "5651": MerchantCategory("Family Clothing Stores", .retail),
        "5661": MerchantCategory("Shoe Stores", .retail),
        "5691": MerchantCategory("Men's and Women's Clothing Stores", .retail),
        "5712": MerchantCategory("Furniture, Home Furnishings", .retail),
        "5722": MerchantCategory("Household Appliance Stores", .retail),
        "5732": MerchantCategory("Electronics Stores", .retail),
        "5733": MerchantCategory("Music Stores", .retail),
        "5734": MerchantCategory("Computer Software Stores", .retail),
        "5735": MerchantCategory("Record Shops", .retail),
        "5811": MerchantCategory("Caterers", .restaurant),
        "5812": MerchantCategory("Eating Places, Restaurants", .restaurant),
        "5813": MerchantCategory("Drinking Places", .restaurant),
        "5814": MerchantCategory("Fast Food Restaurants", .restaurant),
        
        // Services
        "5912": MerchantCategory("Drug Stores and Pharmacies", .healthcare),
        "5921": MerchantCategory("Package Stores-Beer, Wine, Liquor", .retail),
        "5931": MerchantCategory("Used Merchandise and Secondhand Stores", .retail),
        "5932": MerchantCategory("Antique Shops", .retail),
        "5933": MerchantCategory("Pawn Shops", .retail),
        "5940": MerchantCategory("Bicycle Shops", .retail),
        "5941": MerchantCategory("Sporting Goods Stores", .retail),
        "5942": MerchantCategory("Book Stores", .retail),
        "5943": MerchantCategory("Stationery, Office, School Supply Stores", .retail),
        "5944": MerchantCategory("Jewelry Stores, Watches, Clocks", .retail),
        "5945": MerchantCategory("Hobby, Toy, and Game Shops", .retail),
        "5946": MerchantCategory("Camera and Photographic Supply Stores", .retail),
        "5947": MerchantCategory("Gift, Card, Novelty, Souvenir Shops", .retail),
        "5948": MerchantCategory("Luggage and Leather Goods Stores", .retail),
        "5949": MerchantCategory("Sewing, Needlework, Fabric", .retail),
        "5950": MerchantCategory("Glassware, Crystal Stores", .retail),
        
        // Transportation
        "4011": MerchantCategory("Railroads", .transportation),
        "4111": MerchantCategory("Local/Suburban Commuter Passenger Transportation", .transportation),
        "4112": MerchantCategory("Passenger Railways", .transportation),
        "4121": MerchantCategory("Taxicabs/Limousines", .transportation),
        "4131": MerchantCategory("Bus Lines", .transportation),
        "4214": MerchantCategory("Motor Freight Carriers", .transportation),
        "4215": MerchantCategory("Courier Services", .transportation),
        "4411": MerchantCategory("Cruise Lines", .transportation),
        "4511": MerchantCategory("Airlines, Air Carriers", .transportation),
        
        // Utilities
        "4812": MerchantCategory("Telecommunication Equipment", .utilities),
        "4814": MerchantCategory("Telecommunication Services", .utilities),
        "4816": MerchantCategory("Computer Network Services", .utilities),
        "4821": MerchantCategory("Telegraph Services", .utilities),
        "4829": MerchantCategory("Wires, Money Orders", .utilities),
        "4899": MerchantCategory("Cable, Satellite, Other Pay TV", .utilities),
        "4900": MerchantCategory("Utilities", .utilities),
        
        // Healthcare
        "8011": MerchantCategory("Doctors", .healthcare),
        "8021": MerchantCategory("Dentists and Orthodontists", .healthcare),
        "8031": MerchantCategory("Osteopaths", .healthcare),
        "8041": MerchantCategory("Chiropractors", .healthcare),
        "8042": MerchantCategory("Optometrists, Ophthalmologist", .healthcare),
        "8043": MerchantCategory("Opticians, Eyeglasses", .healthcare),
        "8049": MerchantCategory("Podiatrists, Chiropodists", .healthcare),
        "8050": MerchantCategory("Nursing/Personal Care", .healthcare),
        "8062": MerchantCategory("Hospitals", .healthcare),
        "8071": MerchantCategory("Medical and Dental Labs", .healthcare),
        "8099": MerchantCategory("Medical Services", .healthcare),
        
        // Government
        "9211": MerchantCategory("Court Costs", .government),
        "9222": MerchantCategory("Fines - Government Administrative", .government),
        "9311": MerchantCategory("Tax Payments - Government Administrative", .government),
        "9399": MerchantCategory("Government Services", .government),
        
        // Default/Miscellaneous
        "5999": MerchantCategory("Miscellaneous Retail", .retail),
        "7999": MerchantCategory("Miscellaneous Services", .services)
    ]
    
    // MARK: - Public API
    
    /// Determine if MCC indicates P2P transaction
    public func isP2P(mcc: String) -> Bool {
        return Self.p2pMCCs.contains(mcc)
    }
    
    /// Get merchant category information
    public func getMerchantCategory(mcc: String) -> MerchantCategory? {
        return Self.merchantCategories[mcc]
    }
    
    /// Validate MCC format
    public func isValidMCC(_ mcc: String) -> Bool {
        return mcc.count == 4 && mcc.allSatisfy({ $0.isNumber })
    }
    
    /// Get category type for MCC
    public func getCategoryType(mcc: String) -> CategoryType {
        if isP2P(mcc: mcc) {
            return .financial
        }
        return getMerchantCategory(mcc: mcc)?.type ?? .other
    }
    
    /// Get display name for MCC
    public func getDisplayName(mcc: String) -> String {
        if isP2P(mcc: mcc) {
            return "Financial Services"
        }
        return getMerchantCategory(mcc: mcc)?.description ?? "Unknown Merchant (\(mcc))"
    }
    
    /// Suggest appropriate MCCs for business type
    public func suggestMCCs(for businessType: String) -> [String] {
        let searchTerms = businessType.lowercased()
        
        return Self.merchantCategories.compactMap { (mcc, category) in
            if category.description.lowercased().contains(searchTerms) {
                return mcc
            }
            return nil
        }.sorted()
    }
    
    /// Get all MCCs for a category type
    public func getMCCs(for categoryType: CategoryType) -> [String] {
        if categoryType == .financial {
            return Array(Self.p2pMCCs).sorted()
        }
        
        return Self.merchantCategories.compactMap { (mcc, category) in
            category.type == categoryType ? mcc : nil
        }.sorted()
    }
}

// MARK: - Supporting Types

public struct MerchantCategory {
    public let description: String
    public let type: CategoryType
    
    public init(_ description: String, _ type: CategoryType) {
        self.description = description
        self.type = type
    }
}

public enum CategoryType: String, CaseIterable {
    case retail = "Retail"
    case restaurant = "Restaurant"
    case automotive = "Automotive"
    case transportation = "Transportation"
    case utilities = "Utilities"
    case healthcare = "Healthcare"
    case government = "Government"
    case services = "Services"
    case financial = "Financial"
    case other = "Other"
    
    public var displayName: String {
        return rawValue
    }
    
    public var icon: String {
        switch self {
        case .retail: return "bag.fill"
        case .restaurant: return "fork.knife"
        case .automotive: return "car.fill"
        case .transportation: return "airplane"
        case .utilities: return "bolt.fill"
        case .healthcare: return "cross.fill"
        case .government: return "building.columns.fill"
        case .services: return "wrench.and.screwdriver.fill"
        case .financial: return "banknote.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Merchant QR Specific Extensions

extension MerchantCategories {
    
    /// Generate merchant-specific validation rules
    public func getValidationRules(for mcc: String) -> MerchantValidationRules {
        let category = getMerchantCategory(mcc: mcc)
        
        return MerchantValidationRules(
            requiresAmount: !isP2P(mcc: mcc), // P2P can be static, merchants usually need amounts
            requiresCity: true,
            requiresMerchantName: true,
            allowsStaticQR: category?.type != .transportation, // Transport usually needs dynamic
            maxAmountLimit: getMaxAmountLimit(for: category?.type),
            requiredAdditionalFields: getRequiredFields(for: category?.type)
        )
    }
    
    private func getMaxAmountLimit(for categoryType: CategoryType?) -> Decimal? {
        switch categoryType {
        case .transportation:
            return Decimal(50000) // 50,000 KES for transport
        case .government:
            return nil // No limit for government payments
        case .utilities:
            return Decimal(100000) // 100,000 KES for utilities
        default:
            return Decimal(500000) // 500,000 KES general limit
        }
    }
    
    private func getRequiredFields(for categoryType: CategoryType?) -> [String] {
        switch categoryType {
        case .healthcare:
            return ["patient_id", "appointment_reference"]
        case .government:
            return ["reference_number", "service_type"]
        case .transportation:
            return ["route", "ticket_type"]
        case .utilities:
            return ["account_number", "billing_period"]
        default:
            return []
        }
    }
}

public struct MerchantValidationRules {
    public let requiresAmount: Bool
    public let requiresCity: Bool
    public let requiresMerchantName: Bool
    public let allowsStaticQR: Bool
    public let maxAmountLimit: Decimal?
    public let requiredAdditionalFields: [String]
    
    public init(requiresAmount: Bool, requiresCity: Bool, requiresMerchantName: Bool, 
                allowsStaticQR: Bool, maxAmountLimit: Decimal? = nil, 
                requiredAdditionalFields: [String] = []) {
        self.requiresAmount = requiresAmount
        self.requiresCity = requiresCity
        self.requiresMerchantName = requiresMerchantName
        self.allowsStaticQR = allowsStaticQR
        self.maxAmountLimit = maxAmountLimit
        self.requiredAdditionalFields = requiredAdditionalFields
    }
} 