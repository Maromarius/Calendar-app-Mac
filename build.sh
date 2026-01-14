#!/bin/bash

# Calendar Menu Bar App - Build Script

echo "🏗️  Building Calendar Menu Bar App..."

# Set variables
APP_NAME="CalendarMenuBar"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# Clean previous build
if [ -d "$BUILD_DIR" ]; then
    echo "🧹 Cleaning previous build..."
    rm -rf "$BUILD_DIR"
fi

# Create directory structure
echo "📁 Creating app bundle structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy Info.plist
echo "📋 Copying Info.plist..."
cp Info.plist "$CONTENTS_DIR/"

# Compile Swift files
echo "⚙️  Compiling Swift files..."
swiftc -o "${MACOS_DIR}/${APP_NAME}" \
    CalendarApp.swift \
    AppDelegate.swift \
    CalendarViewController.swift \
    CalendarView.swift \
    -framework Cocoa \
    -target arm64-apple-macos11.0

# Check if compilation was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "📦 App bundle created at: ${APP_BUNDLE}"
    echo ""
    echo "🚀 To run the app:"
    echo "   ./run.sh"
    echo ""
    echo "📌 To install to Applications folder:"
    echo "   cp -r ${APP_BUNDLE} /Applications/"
else
    echo "❌ Build failed!"
    exit 1
fi
