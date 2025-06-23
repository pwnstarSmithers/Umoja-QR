package com.qrcodesdk

import com.qrcodesdk.models.QRCodeGenerationRequest
import com.qrcodesdk.models.ParsedQRCode
import com.qrcodesdk.parser.KenyaP2PQRParser
import com.qrcodesdk.models.TLVParsingException

/**
 * Main entry point for QR code operations (mirrors iOS SDK API)
 */
object QRCodeSDK {
    /**
     * Parses a QR code string into a ParsedQRCode object.
     * @param data The EMVCo QR code string to parse.
     * @return ParsedQRCode with all extracted fields.
     * @throws TLVParsingException if parsing fails or the QR is invalid.
     */
    @Throws(TLVParsingException::class)
    fun parseQR(data: String): ParsedQRCode {
        return KenyaP2PQRParser().parseKenyaP2PQR(data)
    }

    /**
     * Generates an EMVCo-compliant QR string from a QRCodeGenerationRequest.
     * @param request The QRCodeGenerationRequest to serialize.
     * @return EMVCo-compliant QR string (TLV format with CRC16).
     */
    fun generateQRString(request: QRCodeGenerationRequest): String {
        return request.toEMVCoString()
    }
} 