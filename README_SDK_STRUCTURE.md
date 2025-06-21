# QRCodeSDK - Proper iOS Framework Structure Guide

## Overview
This document outlines how to properly structure the QRCodeSDK as an iOS framework with embedded unit tests, following Apple's best practices for SDK development.

## Current Issues
- QRCodeSDK is currently just source files in the app project
- Unit tests are in the app's test target, not the SDK's own test target
- No proper framework target configuration
- Tests cannot access XCTest framework properly

## Required Changes

### 1. Create Framework Target
We need to create a new Framework target in Xcode:
- **Target Name**: `QRCodeSDK`
- **Product Type**: Framework
- **Platform**: iOS
- **Language**: Swift

### 2. Create Framework Unit Test Target
Create a dedicated unit test target for the framework:
- **Target Name**: `QRCodeSDKTests`
- **Product Type**: Unit Testing Bundle
- **Host Application**: None (Logic Unit Tests)
- **Allow testing Host Application APIs**: Disabled

### 3. Move Source Files
Move all SDK source files to the framework target:
```
QRCodeSDK/
├── QRCodeSDK.swift (main SDK interface)
├── Models/
│   ├── QRCodeModels.swift
│   ├── PSPDirectory.swift
│   └── MerchantCategories.swift
├── Parser/
│   ├── EnhancedQRParser.swift
│   ├── KenyaP2PQRParser.swift
│   └── TLVParsingError.swift
├── Generator/
│   ├── EnhancedQRGenerator.swift
│   ├── KenyaP2PQRGenerator.swift
│   └── QRBrandingEngine.swift
├── Security/
│   └── SecurityManager.swift
├── Advanced/
│   └── AdvancedFeatures.swift
├── Production/
│   └── ProductionManager.swift
├── Debug/
│   └── DebugTools.swift
└── Utils/
    └── PerformanceOptimizer.swift
```

### 4. Move Unit Tests
Move all unit tests to the framework's test target:
```
QRCodeSDKTests/
├── CBKComplianceTests.swift
├── IntegrationTests.swift
├── KenyaP2MGenerationTests.swift
├── KenyaP2PGenerationTests.swift
├── KenyaP2PParsingTests.swift
├── QRBrandingTests.swift
├── SecurityEdgeCaseTests.swift
└── TanzaniaTANQRTests.swift
```

### 5. Update Access Levels
Make SDK classes and methods public:
```swift
// Before (internal by default)
class EnhancedQRParser {
    func parseQRCode(_ content: String) -> ParsedQRCode? {
        // ...
    }
}

// After (public for SDK)
public class EnhancedQRParser {
    public func parseQRCode(_ content: String) -> ParsedQRCode? {
        // ...
    }
}
```

### 6. Update Test Imports
Use @testable import in test files:
```swift
import XCTest
@testable import QRCodeSDK

class KenyaP2PParsingTests: XCTestCase {
    // Test implementation
}
```

### 7. Update Main App Dependencies
Add framework dependency to main app:
```swift
import QRCodeSDK

class ViewController: UIViewController {
    let qrSDK = QRCodeSDK()
    // ...
}
```

## Benefits of This Structure

### 1. **Proper SDK Architecture**
- Framework is self-contained with its own tests
- Clear separation between SDK and host app
- Professional SDK distribution structure

### 2. **Faster Test Execution**
- Logic unit tests run without host app
- No simulator startup overhead for SDK tests
- Tests run in ~3 seconds vs 20-30 seconds

### 3. **Better Modularity**
- Clear public API surface
- Internal implementation details hidden
- Proper dependency management

### 4. **Industry Standard**
- Follows Apple's recommended practices
- Compatible with CocoaPods, SPM, Carthage
- Professional SDK structure

## Implementation Steps

### Step 1: Add Framework Target
1. Open QRCodeTest.xcodeproj
2. Select project → Add Target
3. Choose "Framework" template
4. Name it "QRCodeSDK"
5. Set deployment target to iOS 12.0+

### Step 2: Add Framework Test Target
1. Add new target → Unit Testing Bundle
2. Name it "QRCodeSDKTests"
3. Set Host Application to "None"
4. Disable "Allow testing Host Application APIs"

### Step 3: Move Source Files
1. Select all QRCodeSDK source files
2. Update target membership to QRCodeSDK framework
3. Remove from main app target

### Step 4: Move Test Files
1. Select all SDK test files from QRCodeTestTests
2. Move to QRCodeSDKTests target
3. Update imports to use @testable import QRCodeSDK

### Step 5: Update Access Levels
1. Add public keyword to all SDK classes
2. Add public keyword to all SDK methods
3. Keep internal implementation details internal

### Step 6: Update App Dependencies
1. Add QRCodeSDK framework to app dependencies
2. Update app imports to use framework
3. Test app builds and runs correctly

## Testing the New Structure

### Run SDK Tests
```bash
xcodebuild test -project QRCodeTest.xcodeproj -scheme QRCodeSDKTests -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Run App Tests
```bash
xcodebuild test -project QRCodeTest.xcodeproj -scheme QRCodeTest -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Verify Framework Build
```bash
xcodebuild build -project QRCodeTest.xcodeproj -scheme QRCodeSDK -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Expected Results

### Before (Current Issues):
- ❌ Tests can't find XCTest framework
- ❌ Tests run in app context (slow)
- ❌ No clear SDK boundary
- ❌ Not distributable as standalone SDK

### After (Proper Structure):
- ✅ Tests run as logic unit tests (fast)
- ✅ Clear SDK framework boundary
- ✅ Professional distribution structure
- ✅ Proper access control
- ✅ XCTest framework accessible

## Maintenance Notes

### When Adding New SDK Classes:
1. Add to QRCodeSDK framework target
2. Mark appropriate methods as public
3. Add corresponding unit tests to QRCodeSDKTests

### When Adding New Tests:
1. Add to QRCodeSDKTests target (not app tests)
2. Use @testable import QRCodeSDK
3. Test only public SDK APIs where possible

### When Updating Public APIs:
1. Consider backward compatibility
2. Update documentation
3. Add comprehensive test coverage

This structure ensures the QRCodeSDK follows iOS framework best practices and can be properly tested, distributed, and maintained as a professional SDK. 