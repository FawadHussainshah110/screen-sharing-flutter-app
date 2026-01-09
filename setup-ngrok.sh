#!/bin/bash

# Mirror Phone Scan - ngrok Setup Script
# Automates ngrok configuration for cross-network testing

echo "🌐 Mirror Phone Scan - ngrok Setup"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo -e "${RED}❌ ngrok is not installed${NC}"
    echo ""
    echo "Please install ngrok first:"
    echo -e "${CYAN}  Mac:${NC} brew install ngrok"
    echo -e "${CYAN}  Or download from:${NC} https://ngrok.com/download"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ ngrok is installed${NC}"
echo ""

# Check if server is running
if ! lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${YELLOW}⚠️  Server is not running on port 3000${NC}"
    echo ""
    echo "Please start the server first:"
    echo -e "${CYAN}  cd server && npm start${NC}"
    echo ""
    read -p "Press Enter after starting the server..."
fi

echo -e "${GREEN}✅ Server detected on port 3000${NC}"
echo ""

# Start ngrok in background
echo "🚀 Starting ngrok tunnel..."
ngrok http 3000 > /dev/null &
NGROK_PID=$!

# Wait for ngrok to start
sleep 3

# Get ngrok URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"https://[^"]*' | grep -o 'https://[^"]*' | head -1)

if [ -z "$NGROK_URL" ]; then
    echo -e "${RED}❌ Failed to get ngrok URL${NC}"
    echo "Make sure ngrok started successfully"
    kill $NGROK_PID 2>/dev/null
    exit 1
fi

echo -e "${GREEN}✅ ngrok tunnel created!${NC}"
echo ""
echo "======================================"
echo -e "${CYAN}Your Public URL:${NC}"
echo -e "${GREEN}${NGROK_URL}${NC}"
echo "======================================"
echo ""

# Update constants.dart
CONSTANTS_FILE="lib/utils/constants.dart"

if [ ! -f "$CONSTANTS_FILE" ]; then
    echo -e "${RED}❌ Constants file not found!${NC}"
    kill $NGROK_PID 2>/dev/null
    exit 1
fi

# Backup original
cp "$CONSTANTS_FILE" "${CONSTANTS_FILE}.ngrok.backup"

# Update serverUrl
sed -i.bak "s|static const String serverUrl = 'http://[^']*';|static const String serverUrl = '${NGROK_URL}';|g" "$CONSTANTS_FILE"

echo -e "${GREEN}✅ Updated lib/utils/constants.dart${NC}"
echo ""

echo "======================================"
echo -e "${CYAN}Next Steps:${NC}"
echo "======================================"
echo ""
echo "1. Open PC browser:"
echo -e "   ${GREEN}${NGROK_URL}${NC}"
echo ""
echo "2. Rebuild mobile app:"
echo -e "   ${CYAN}flutter run${NC}"
echo ""
echo "3. Scan QR code from anywhere!"
echo ""
echo -e "${YELLOW}📝 Note:${NC}"
echo "  - This URL is temporary (changes on restart)"
echo "  - Keep this terminal open"
echo "  - Press Ctrl+C to stop ngrok"
echo ""
echo -e "${CYAN}View ngrok dashboard:${NC}"
echo "  http://localhost:4040"
echo ""

# Keep script running
echo "Press Ctrl+C to stop ngrok and restore original settings..."
echo ""

# Trap Ctrl+C
trap cleanup INT

cleanup() {
    echo ""
    echo "🛑 Stopping ngrok..."
    kill $NGROK_PID 2>/dev/null
    
    # Restore original constants
    if [ -f "${CONSTANTS_FILE}.ngrok.backup" ]; then
        mv "${CONSTANTS_FILE}.ngrok.backup" "$CONSTANTS_FILE"
        echo -e "${GREEN}✅ Restored original constants.dart${NC}"
    fi
    
    echo "👋 Goodbye!"
    exit 0
}

# Wait for user to press Ctrl+C
wait $NGROK_PID
