package com.qrcodesdk.parser

import com.qrcodesdk.models.*
import com.qrcodesdk.QRCodeSDK
import java.math.BigDecimal

fun buildValidKenyaP2PQR(
    recipientName: String = "Test User",
    recipientIdentifier: String = "1234567890",
    amount: BigDecimal? = null,
    mcc: String = "6011",
    currency: String = "404",
    countryCode: String = "KE",
    pspGuid: String = "ke.go.qr",
    pspType: PSPInfo.PSPType = PSPInfo.PSPType.BANK,
    participantId: String = "68072226665"
): String {
    val pspInfo = PSPInfo(
        type = pspType,
        identifier = pspGuid,
        name = "CBK Standard",
        country = Country.KENYA
    )
    val accountTemplate = AccountTemplate(
        tag = "29",
        guid = pspGuid,
        participantId = participantId,
        pspInfo = pspInfo
    )
    val request = QRCodeGenerationRequest(
        qrType = QRType.P2P,
        initiationMethod = QRInitiationMethod.STATIC,
        accountTemplates = listOf(accountTemplate),
        merchantCategoryCode = mcc,
        amount = amount,
        recipientName = recipientName,
        recipientIdentifier = recipientIdentifier,
        currency = currency,
        countryCode = countryCode
    )
    return QRCodeSDK.generateQRString(request)
} 