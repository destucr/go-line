#!/bin/bash

# capture_screenshots.sh
# A script to capture current simulator screen for the README.

# Create screenshots directory if it doesn't exist
mkdir -p screenshots

echo "📸 Preparing to take screenshots from the iOS Simulator..."
echo "Please ensure your app is running in the Simulator."

# Function to capture
capture() {
    local name=$1
    echo "Capturing $name..."
    xcrun simctl io booted screenshot "screenshots/${name}.png"
}

# Prompt user to navigate to each screen
read -p "1. Navigate to MENU screen and press ENTER..."
capture "menu"

read -p "2. Navigate to GAMEPLAY screen and press ENTER..."
capture "gameplay"

read -p "3. Navigate to SHOP screen (End of Day) and press ENTER..."
capture "shop"

read -p "4. Navigate to GUIDE screen and press ENTER..."
capture "guide"

echo "✅ All screenshots saved to the 'screenshots/' folder!"
echo "Don't forget to commit them to your repository."
