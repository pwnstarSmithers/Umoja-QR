#!/bin/bash

# Fresh Build Script - Following Cursor Rules
# This script implements the "fresh build" rule from .cursor-rules.yml

echo "🔥 Starting Fresh Build Process..."
echo "📋 Following cursor-rules.yml 'fresh build' requirements"

# Step 1: Kill all Java processes to prevent conflicts
echo "1️⃣ Killing Java processes..."
pkill -f java || echo "   ℹ️  No Java processes found to kill"
pkill -f gradle || echo "   ℹ️  No Gradle processes found to kill"

# Step 2: Stop Gradle daemon gracefully
echo "2️⃣ Stopping Gradle daemon..."
./gradlew --stop

# Step 3: Clean build artifacts
echo "3️⃣ Cleaning build artifacts..."
./gradlew clean

# Step 4: Run tests first (mandatory per cursor rules)
echo "4️⃣ Running unit tests (required before build)..."
./gradlew :qrcode-sdk:testDebugUnitTest

# Step 5: Check if tests passed
if [ $? -eq 0 ]; then
    echo "✅ Tests passed! Proceeding with build..."
    
    # Step 6: Fresh build
    echo "5️⃣ Running fresh build..."
    ./gradlew build
    
    if [ $? -eq 0 ]; then
        echo "🎉 Fresh build completed successfully!"
        echo "📊 Build artifacts are clean and ready for deployment"
    else
        echo "❌ Build failed after clean start"
        exit 1
    fi
else
    echo "❌ Tests failed! Build aborted per cursor rules"
    exit 1
fi

echo "✨ Fresh build process complete!" 