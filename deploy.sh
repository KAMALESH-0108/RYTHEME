#!/bin/bash
set -e

echo "===================================================="
echo "🚀 RYTHEME Production Build & Deployment Pipeline"
echo "===================================================="

# Step 1: Build Flutter Web Frontend
echo ""
echo "📱 [1/3] Building Flutter Web Client..."
flutter pub get
flutter build web --release

# Step 2: Build JioSaavn API Engine
echo ""
echo "🎵 [2/3] Building JioSaavn Open-Source API Engine..."
cd jiosaavn-api
npm install
npm run build
cd ..

# Step 3: Install Production Backend Dependencies
echo ""
echo "🌐 [3/3] Preparing Express Production Server..."
cd backend
npm install --production
cd ..

echo ""
echo "===================================================="
echo "✅ Build Complete! Launching Production Stack..."
echo "===================================================="
cd backend
node start-production.js
