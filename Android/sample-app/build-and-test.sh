#!/bin/bash

# QR Code SDK Build and Test Script
# This script handles building, testing, and quality checks

set -e  # Exit on any error

echo "🚀 Starting QR Code SDK build and test process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
print_status "Checking prerequisites..."

if ! command_exists java; then
    print_error "Java is not installed"
    exit 1
fi

if ! command_exists ./gradlew; then
    print_error "Gradle wrapper not found"
    exit 1
fi

# Print Java version
JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
print_status "Java version: $JAVA_VERSION"

# Clean previous builds
print_status "Cleaning previous builds..."
./gradlew clean

# Run unit tests for SDK
print_status "Running SDK unit tests..."
if ./gradlew :qrcode-sdk:testDebugUnitTest; then
    print_success "SDK tests passed"
else
    print_error "SDK tests failed"
    exit 1
fi

# Run unit tests for app
print_status "Running app unit tests..."
if ./gradlew :app:testDebugUnitTest; then
    print_success "App tests passed"
else
    print_error "App tests failed"
    exit 1
fi

# Run lint checks
print_status "Running lint checks..."
if ./gradlew lint; then
    print_success "Lint checks passed"
else
    print_warning "Lint checks found issues"
fi

# Build debug version
print_status "Building debug version..."
if ./gradlew assembleDebug; then
    print_success "Debug build completed"
else
    print_error "Debug build failed"
    exit 1
fi

# Build release version
print_status "Building release version..."
if ./gradlew assembleRelease; then
    print_success "Release build completed"
else
    print_error "Release build failed"
    exit 1
fi

# Generate SDK documentation
print_status "Generating SDK documentation..."
if ./gradlew :qrcode-sdk:dokka; then
    print_success "Documentation generated"
else
    print_warning "Documentation generation failed"
fi

# Check build artifacts
print_status "Checking build artifacts..."
if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
    print_success "Debug APK created"
else
    print_error "Debug APK not found"
    exit 1
fi

if [ -f "app/build/outputs/apk/release/app-release.apk" ]; then
    print_success "Release APK created"
else
    print_error "Release APK not found"
    exit 1
fi

if [ -f "qrcode-sdk/build/outputs/aar/qrcode-sdk-release.aar" ]; then
    print_success "SDK AAR created"
else
    print_error "SDK AAR not found"
    exit 1
fi

# Run integration tests if available
if [ -d "app/src/androidTest" ]; then
    print_status "Running integration tests..."
    if ./gradlew :app:connectedAndroidTest; then
        print_success "Integration tests passed"
    else
        print_warning "Integration tests failed or no device connected"
    fi
fi

# Generate test reports
print_status "Generating test reports..."
./gradlew :qrcode-sdk:testDebugUnitTest --continue
./gradlew :app:testDebugUnitTest --continue

# Print summary
echo ""
print_success "Build and test process completed successfully!"
echo ""
print_status "Build artifacts:"
echo "  - Debug APK: app/build/outputs/apk/debug/app-debug.apk"
echo "  - Release APK: app/build/outputs/apk/release/app-release.apk"
echo "  - SDK AAR: qrcode-sdk/build/outputs/aar/qrcode-sdk-release.aar"
echo ""
print_status "Test reports:"
echo "  - SDK tests: qrcode-sdk/build/reports/tests/testDebugUnitTest/"
echo "  - App tests: app/build/reports/tests/testDebugUnitTest/"
echo ""

# Optional: Upload to Maven repository
if [ "$1" = "--publish" ]; then
    print_status "Publishing to Maven repository..."
    if ./gradlew :qrcode-sdk:publishReleasePublicationToMavenRepository; then
        print_success "Published to Maven repository"
    else
        print_error "Failed to publish to Maven repository"
        exit 1
    fi
fi

print_success "All done! 🎉" 