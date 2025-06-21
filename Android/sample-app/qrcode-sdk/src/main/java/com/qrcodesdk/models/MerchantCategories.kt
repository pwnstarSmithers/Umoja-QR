package com.qrcodesdk.models

import java.math.BigDecimal

/**
 * Merchant Category Code Management for Kenya P2M QR Code Support
 * Phase 2 implementation supporting comprehensive MCC validation and merchant-specific rules
 */
object MerchantCategories {
    
    // MARK: - P2P MCCs (Financial Services)
    
    /** MCCs that indicate P2P (person-to-person) transactions */
    val P2P_MCCS = setOf(
        "6011", // Financial Institutions - Automated Cash Disbursements
        "6012", // Financial Institutions - Merchandise and Services
        "6051", // Quasi Cash - Financial Institutions
        "6211", // Securities Brokers/Dealers
        "6540"  // Non-financial Institution - POI Funding
    )
    
    // MARK: - Common Merchant Categories
    
    /** Common merchant categories with descriptions */
    val MERCHANT_CATEGORIES = mapOf(
        // Retail
        "5311" to MerchantCategory("Department Stores", CategoryType.RETAIL),
        "5411" to MerchantCategory("Grocery Stores, Supermarkets", CategoryType.RETAIL),
        "5422" to MerchantCategory("Freezer and Locker Meat Provisioners", CategoryType.RETAIL),
        "5441" to MerchantCategory("Candy, Nut, and Confectionery Stores", CategoryType.RETAIL),
        "5451" to MerchantCategory("Dairy Products Stores", CategoryType.RETAIL),
        "5462" to MerchantCategory("Bakeries", CategoryType.RETAIL),
        "5499" to MerchantCategory("Miscellaneous Food Stores", CategoryType.RETAIL),
        "5511" to MerchantCategory("Car and Truck Dealers", CategoryType.AUTOMOTIVE),
        "5541" to MerchantCategory("Service Stations", CategoryType.AUTOMOTIVE),
        "5542" to MerchantCategory("Automated Fuel Dispensers", CategoryType.AUTOMOTIVE),
        "5611" to MerchantCategory("Men's and Boys' Clothing", CategoryType.RETAIL),
        "5621" to MerchantCategory("Women's Ready-to-Wear Stores", CategoryType.RETAIL),
        "5631" to MerchantCategory("Women's Accessory Stores", CategoryType.RETAIL),
        "5641" to MerchantCategory("Children's and Infants' Wear Stores", CategoryType.RETAIL),
        "5651" to MerchantCategory("Family Clothing Stores", CategoryType.RETAIL),
        "5661" to MerchantCategory("Shoe Stores", CategoryType.RETAIL),
        "5691" to MerchantCategory("Men's and Women's Clothing Stores", CategoryType.RETAIL),
        "5712" to MerchantCategory("Furniture, Home Furnishings", CategoryType.RETAIL),
        "5722" to MerchantCategory("Household Appliance Stores", CategoryType.RETAIL),
        "5732" to MerchantCategory("Electronics Stores", CategoryType.RETAIL),
        "5733" to MerchantCategory("Music Stores", CategoryType.RETAIL),
        "5734" to MerchantCategory("Computer Software Stores", CategoryType.RETAIL),
        "5735" to MerchantCategory("Record Shops", CategoryType.RETAIL),
        "5811" to MerchantCategory("Caterers", CategoryType.RESTAURANT),
        "5812" to MerchantCategory("Eating Places, Restaurants", CategoryType.RESTAURANT),
        "5813" to MerchantCategory("Drinking Places", CategoryType.RESTAURANT),
        "5814" to MerchantCategory("Fast Food Restaurants", CategoryType.RESTAURANT),
        
        // Services
        "5912" to MerchantCategory("Drug Stores and Pharmacies", CategoryType.HEALTHCARE),
        "5921" to MerchantCategory("Package Stores-Beer, Wine, Liquor", CategoryType.RETAIL),
        "5931" to MerchantCategory("Used Merchandise and Secondhand Stores", CategoryType.RETAIL),
        "5932" to MerchantCategory("Antique Shops", CategoryType.RETAIL),
        "5933" to MerchantCategory("Pawn Shops", CategoryType.RETAIL),
        "5940" to MerchantCategory("Bicycle Shops", CategoryType.RETAIL),
        "5941" to MerchantCategory("Sporting Goods Stores", CategoryType.RETAIL),
        "5942" to MerchantCategory("Book Stores", CategoryType.RETAIL),
        "5943" to MerchantCategory("Stationery, Office, School Supply Stores", CategoryType.RETAIL),
        "5944" to MerchantCategory("Jewelry Stores, Watches, Clocks", CategoryType.RETAIL),
        "5945" to MerchantCategory("Hobby, Toy, and Game Shops", CategoryType.RETAIL),
        "5946" to MerchantCategory("Camera and Photographic Supply Stores", CategoryType.RETAIL),
        "5947" to MerchantCategory("Gift, Card, Novelty, Souvenir Shops", CategoryType.RETAIL),
        "5948" to MerchantCategory("Luggage and Leather Goods Stores", CategoryType.RETAIL),
        "5949" to MerchantCategory("Sewing, Needlework, Fabric", CategoryType.RETAIL),
        "5950" to MerchantCategory("Glassware, Crystal Stores", CategoryType.RETAIL),
        
        // Transportation
        "4011" to MerchantCategory("Railroads", CategoryType.TRANSPORTATION),
        "4111" to MerchantCategory("Local/Suburban Commuter Passenger Transportation", CategoryType.TRANSPORTATION),
        "4112" to MerchantCategory("Passenger Railways", CategoryType.TRANSPORTATION),
        "4121" to MerchantCategory("Taxicabs/Limousines", CategoryType.TRANSPORTATION),
        "4131" to MerchantCategory("Bus Lines", CategoryType.TRANSPORTATION),
        "4214" to MerchantCategory("Motor Freight Carriers", CategoryType.TRANSPORTATION),
        "4215" to MerchantCategory("Courier Services", CategoryType.TRANSPORTATION),
        "4411" to MerchantCategory("Cruise Lines", CategoryType.TRANSPORTATION),
        "4511" to MerchantCategory("Airlines, Air Carriers", CategoryType.TRANSPORTATION),
        
        // Utilities
        "4812" to MerchantCategory("Telecommunication Equipment", CategoryType.UTILITIES),
        "4814" to MerchantCategory("Telecommunication Services", CategoryType.UTILITIES),
        "4816" to MerchantCategory("Computer Network Services", CategoryType.UTILITIES),
        "4821" to MerchantCategory("Telegraph Services", CategoryType.UTILITIES),
        "4829" to MerchantCategory("Wires, Money Orders", CategoryType.UTILITIES),
        "4899" to MerchantCategory("Cable, Satellite, Other Pay TV", CategoryType.UTILITIES),
        "4900" to MerchantCategory("Utilities", CategoryType.UTILITIES),
        
        // Healthcare
        "8011" to MerchantCategory("Doctors", CategoryType.HEALTHCARE),
        "8021" to MerchantCategory("Dentists and Orthodontists", CategoryType.HEALTHCARE),
        "8031" to MerchantCategory("Osteopaths", CategoryType.HEALTHCARE),
        "8041" to MerchantCategory("Chiropractors", CategoryType.HEALTHCARE),
        "8042" to MerchantCategory("Optometrists, Ophthalmologist", CategoryType.HEALTHCARE),
        "8043" to MerchantCategory("Opticians, Eyeglasses", CategoryType.HEALTHCARE),
        "8049" to MerchantCategory("Podiatrists, Chiropodists", CategoryType.HEALTHCARE),
        "8050" to MerchantCategory("Nursing/Personal Care", CategoryType.HEALTHCARE),
        "8062" to MerchantCategory("Hospitals", CategoryType.HEALTHCARE),
        "8071" to MerchantCategory("Medical and Dental Labs", CategoryType.HEALTHCARE),
        "8099" to MerchantCategory("Medical Services", CategoryType.HEALTHCARE),
        
        // Government
        "9211" to MerchantCategory("Court Costs", CategoryType.GOVERNMENT),
        "9222" to MerchantCategory("Fines - Government Administrative", CategoryType.GOVERNMENT),
        "9311" to MerchantCategory("Tax Payments - Government Administrative", CategoryType.GOVERNMENT),
        "9399" to MerchantCategory("Government Services", CategoryType.GOVERNMENT),
        
        // Default/Miscellaneous
        "5999" to MerchantCategory("Miscellaneous Retail", CategoryType.RETAIL),
        "7999" to MerchantCategory("Miscellaneous Services", CategoryType.SERVICES)
    )
    
    // MARK: - Public API
    
    /** Determine if MCC indicates P2P transaction */
    fun isP2P(mcc: String): Boolean = P2P_MCCS.contains(mcc)
    
    /** Get merchant category information */
    fun getMerchantCategory(mcc: String): MerchantCategory? = MERCHANT_CATEGORIES[mcc]
    
    /** Validate MCC format */
    fun isValidMCC(mcc: String): Boolean {
        return mcc.length == 4 && mcc.all { it.isDigit() }
    }
    
    /** Get category type for MCC */
    fun getCategoryType(mcc: String): CategoryType {
        return if (isP2P(mcc)) {
            CategoryType.FINANCIAL
        } else {
            getMerchantCategory(mcc)?.type ?: CategoryType.OTHER
        }
    }
    
    /** Get display name for MCC */
    fun getDisplayName(mcc: String): String {
        return if (isP2P(mcc)) {
            "Financial Services"
        } else {
            getMerchantCategory(mcc)?.description ?: "Unknown Merchant ($mcc)"
        }
    }
    
    /** Suggest appropriate MCCs for business type */
    fun suggestMCCs(businessType: String): List<String> {
        val searchTerms = businessType.lowercase()
        
        return MERCHANT_CATEGORIES.filterValues { category ->
            category.description.lowercase().contains(searchTerms)
        }.keys.sorted()
    }
    
    /** Get all MCCs for a category type */
    fun getMCCs(categoryType: CategoryType): List<String> {
        return if (categoryType == CategoryType.FINANCIAL) {
            P2P_MCCS.sorted()
        } else {
            MERCHANT_CATEGORIES.filterValues { it.type == categoryType }.keys.sorted()
        }
    }
    
    /** Generate merchant-specific validation rules */
    fun getValidationRules(mcc: String): MerchantValidationRules {
        val category = getMerchantCategory(mcc)
        
        return MerchantValidationRules(
            requiresAmount = !isP2P(mcc), // P2P can be static, merchants usually need amounts
            requiresCity = true,
            requiresMerchantName = true,
            allowsStaticQR = category?.type != CategoryType.TRANSPORTATION, // Transport usually needs dynamic
            maxAmountLimit = getMaxAmountLimit(category?.type),
            requiredAdditionalFields = getRequiredFields(category?.type)
        )
    }
    
    private fun getMaxAmountLimit(categoryType: CategoryType?): BigDecimal? {
        return when (categoryType) {
            CategoryType.TRANSPORTATION -> BigDecimal("50000") // 50,000 KES for transport
            CategoryType.GOVERNMENT -> null // No limit for government payments
            CategoryType.UTILITIES -> BigDecimal("100000") // 100,000 KES for utilities
            else -> BigDecimal("500000") // 500,000 KES general limit
        }
    }
    
    private fun getRequiredFields(categoryType: CategoryType?): List<String> {
        return when (categoryType) {
            CategoryType.HEALTHCARE -> listOf("patient_id", "appointment_reference")
            CategoryType.GOVERNMENT -> listOf("reference_number", "service_type")
            CategoryType.TRANSPORTATION -> listOf("route", "ticket_type")
            CategoryType.UTILITIES -> listOf("account_number", "billing_period")
            else -> emptyList()
        }
    }
}

// MARK: - Supporting Types

data class MerchantCategory(
    val description: String,
    val type: CategoryType
)

enum class CategoryType(val displayName: String) {
    RETAIL("Retail"),
    RESTAURANT("Restaurant"),
    AUTOMOTIVE("Automotive"),
    TRANSPORTATION("Transportation"),
    UTILITIES("Utilities"),
    HEALTHCARE("Healthcare"),
    GOVERNMENT("Government"),
    SERVICES("Services"),
    FINANCIAL("Financial"),
    OTHER("Other");
    
    fun getIcon(): String {
        return when (this) {
            RETAIL -> "shopping_bag"
            RESTAURANT -> "restaurant"
            AUTOMOTIVE -> "directions_car"
            TRANSPORTATION -> "flight"
            UTILITIES -> "flash_on"
            HEALTHCARE -> "local_hospital"
            GOVERNMENT -> "account_balance"
            SERVICES -> "build"
            FINANCIAL -> "account_balance_wallet"
            OTHER -> "help_outline"
        }
    }
}

data class MerchantValidationRules(
    val requiresAmount: Boolean,
    val requiresCity: Boolean,
    val requiresMerchantName: Boolean,
    val allowsStaticQR: Boolean,
    val maxAmountLimit: BigDecimal? = null,
    val requiredAdditionalFields: List<String> = emptyList()
) 