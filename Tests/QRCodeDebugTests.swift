import XCTest
@testable import QRCodeSDK

class QRCodeDebugTests: XCTestCase {
    
    func testDebugMalformedQRCode1() {
        let sdk = QRCodeSDK()
        let qrString = "00020101021129230004EQLT6811dummy1234565204601153034045802KE5916Sanford Smithers601225471234567862120808Transfer630478CD"
        
        print("🔍 Debugging QR Code 1...")
        let debugInfo = sdk.debugQRCode(qrString)
        print(debugInfo)
        
        print("\n🔍 Parsing with diagnostics...")
        let result = sdk.parseQRWithDiagnostics(qrString)
        
        switch result {
        case .success(let parsed):
            print("✅ Parsing successful!")
            print("Recipient: \(parsed.recipientName ?? "Unknown")")
        case .failure(let error, let diagnostics):
            print("❌ Parsing failed: \(error.localizedDescription)")
            print("📊 Diagnostics:")
            print(diagnostics)
        }
    }
    
    func testDebugMalformedQRCode2() {
        let sdk = QRCodeSDK()
        let qrString = "00020101021128280008ke.go.qr011225476930074329120008ke.go.qr5204000053034045802KE5912YUSUF MUGALU610200620605020482320008ke.go.qr0116171062025 05067583380010m-pesa.com01020203050000004050000063040C53"
        
        print("🔍 Debugging QR Code 2...")
        let debugInfo = sdk.debugQRCode(qrString)
        print(debugInfo)
        
        print("\n🔍 Parsing with diagnostics...")
        let result = sdk.parseQRWithDiagnostics(qrString)
        
        switch result {
        case .success(let parsed):
            print("✅ Parsing successful!")
            print("Recipient: \(parsed.recipientName ?? "Unknown")")
        case .failure(let error, let diagnostics):
            print("❌ Parsing failed: \(error.localizedDescription)")
            print("📊 Diagnostics:")
            print(diagnostics)
        }
    }
    
    func testFixedQRCode1() {
        let sdk = QRCodeSDK()
        // Fixed version of QR Code 1 - corrected tag 62 length from 12 to 10
        let qrString = "00020101021129230004EQLT6811dummy1234565204601153034045802KE5916Sanford Smithers601225471234567862100808Transfer630478CD"
        
        print("🔍 Testing fixed QR Code 1...")
        let result = sdk.parseQRWithDiagnostics(qrString)
        
        switch result {
        case .success(let parsed):
            print("✅ Fixed QR parsing successful!")
            print("Recipient: \(parsed.recipientName ?? "Unknown")")
            print("Purpose: \(parsed.additionalData?.purposeOfTransaction ?? "None")")
        case .failure(let error, let diagnostics):
            print("❌ Fixed QR still failing: \(error.localizedDescription)")
            print("📊 Diagnostics:")
            print(diagnostics)
        }
    }
    
    func testProductionQRCode() {
        let sdk = QRCodeSDK()
        let qrString = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Thika Vivian Stores6002KE61020082310008ke.go.qr011511062025T1259066304AA94"
        
        print("🔍 Debugging Production QR Code...")
        let debugInfo = sdk.debugQRCode(qrString)
        print(debugInfo)
        
        print("\n🔍 Parsing with diagnostics...")
        let result = sdk.parseQRWithDiagnostics(qrString)
        
        switch result {
        case .success(let parsed):
            print("✅ Production QR parsing successful!")
            print("Recipient: \(parsed.recipientName ?? "Unknown")")
            print("Country: \(parsed.countryCode)")
            print("Currency: \(parsed.currency)")
        case .failure(let error, let diagnostics):
            print("❌ Production QR parsing failed: \(error.localizedDescription)")
            print("📊 Diagnostics:")
            print(diagnostics)
        }
    }
} 