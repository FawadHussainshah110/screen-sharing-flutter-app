#!/bin/bash

# Mirror Phone Scan - Setup Script
# This script automates the initial setup process

echo "🚀 Mirror Phone Scan - Setup Script"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Get local IP address
echo "📡 Step 1: Detecting your local IP address..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n1)
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    LOCAL_IP=$(hostname -I | awk '{print $1}')
else
    echo -e "${RED}❌ Unsupported OS. Please manually find your IP address.${NC}"
    exit 1
fi

if [ -z "$LOCAL_IP" ]; then
    echo -e "${RED}❌ Could not detect IP address automatically.${NC}"
    echo "Please run: ipconfig (Windows) or ifconfig (Mac/Linux)"
    exit 1
fi

echo -e "${GREEN}✅ Found IP: $LOCAL_IP${NC}"
echo ""

# Step 2: Update constants.dart
echo "📝 Step 2: Updating Flutter constants with your IP..."
CONSTANTS_FILE="lib/utils/constants.dart"

if [ ! -f "$CONSTANTS_FILE" ]; then
    echo -e "${RED}❌ Constants file not found!${NC}"
    exit 1
fi

# Backup original file
cp "$CONSTANTS_FILE" "${CONSTANTS_FILE}.backup"

# Update the server URL
sed -i.bak "s|http://192.168.1.100:3000|http://${LOCAL_IP}:3000|g" "$CONSTANTS_FILE"

echo -e "${GREEN}✅ Updated server URL to: http://${LOCAL_IP}:3000${NC}"
echo ""

# Step 3: Install server dependencies
echo "📦 Step 3: Installing server dependencies..."
cd server

if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Server package.json not found!${NC}"
    cd ..
    exit 1
fi

npm install

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Server dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install server dependencies${NC}"
    cd ..
    exit 1
fi

cd ..
echo ""

# Step 4: Install Flutter dependencies
echo "📦 Step 4: Installing Flutter dependencies..."

if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}⚠️  Flutter not found. Please install Flutter first.${NC}"
    echo "Visit: https://flutter.dev/docs/get-started/install"
else
    flutter pub get
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Flutter dependencies installed${NC}"
    else
        echo -e "${RED}❌ Failed to install Flutter dependencies${NC}"
        exit 1
    fi
fi

echo ""
echo "======================================"
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo "======================================"
echo ""
echo "Next steps:"
echo "  1. Start the server:"
echo "     $ cd server && npm start"
echo ""
echo "  2. In another terminal, run the Flutter app:"
echo "     $ flutter run"
echo ""
echo "  3. Open browser on your PC:"
echo "     http://$LOCAL_IP:3000"
echo ""
echo "  4. Scan the QR code with your mobile app!"
echo ""
echo -e "${YELLOW}📝 Note: Make sure both devices are on the same WiFi network${NC}"
echo ""
