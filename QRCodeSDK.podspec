Pod::Spec.new do |spec|
  spec.name                   = "QRCodeSDK"
  spec.version                = "1.0.0"
  spec.summary                = "Professional Payment QR Code SDK for Kenya and Tanzania"
  spec.description            = <<-DESC
    QRCode SDK is a comprehensive, production-ready payment QR code solution supporting 
    Kenya (KE-QR) and Tanzania (TAN-QR) standards with EMVCo compliance, advanced branding 
    capabilities, and enterprise-grade security features.
                             DESC

  spec.homepage               = "https://github.com/yourusername/QRCodeSDK"
  spec.license                = { :type => "MIT", :file => "LICENSE" }
  spec.author                 = { "QRCodeSDK Team" => "support@qrcodesdk.com" }
  spec.source                 = { :git => "https://github.com/yourusername/QRCodeSDK.git", :tag => "#{spec.version}" }
  
  spec.ios.deployment_target  = "12.0"
  spec.osx.deployment_target  = "11.0"
  spec.tvos.deployment_target = "12.0"
  spec.watchos.deployment_target = "6.0"
  
  spec.swift_versions         = ["5.0", "5.1", "5.2", "5.3", "5.4", "5.5", "5.6", "5.7", "5.8", "5.9"]
  
  spec.source_files           = "Sources/QRCodeSDK/**/*.swift"
  spec.resource_bundles       = {
    'QRCodeSDK' => ['Sources/QRCodeSDK/QRCodeSDK.docc/**/*']
  }
  
  spec.frameworks             = "Foundation", "UIKit", "CoreImage", "CryptoKit"
  spec.requires_arc           = true
  
  spec.pod_target_xcconfig    = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_VERSION' => '5.0'
  }
  
  spec.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/**/*.swift'
    test_spec.dependency 'XCTest'
  end
  
  # Subspec for advanced features (optional)
  spec.subspec 'Advanced' do |ss|
    ss.source_files = 'Sources/QRCodeSDK/Advanced/**/*.swift'
    ss.dependency 'QRCodeSDK/Core'
  end
  
  # Core subspec
  spec.subspec 'Core' do |ss|
    ss.source_files = [
      'Sources/QRCodeSDK/QRCodeSDK.swift',
      'Sources/QRCodeSDK/Models/**/*.swift',
      'Sources/QRCodeSDK/Parser/**/*.swift',
      'Sources/QRCodeSDK/Generator/**/*.swift',
      'Sources/QRCodeSDK/Security/**/*.swift',
      'Sources/QRCodeSDK/Utils/**/*.swift'
    ]
  end
  
  # Production monitoring subspec (optional)
  spec.subspec 'Production' do |ss|
    ss.source_files = 'Sources/QRCodeSDK/Production/**/*.swift'
    ss.dependency 'QRCodeSDK/Core'
  end
  
  # Debug tools subspec (optional, debug builds only)
  spec.subspec 'Debug' do |ss|
    ss.source_files = 'Sources/QRCodeSDK/Debug/**/*.swift'
    ss.dependency 'QRCodeSDK/Core'
    ss.pod_target_xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'DEBUG'
    }
  end
  
end 