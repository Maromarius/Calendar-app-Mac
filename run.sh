#!/bin/bash

# Calendar Menu Bar App - Run Script

APP_NAME="CalendarMenuBar"
APP_BUNDLE="build/${APP_NAME}.app"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ App not built yet. Run ./build.sh first"
    exit 1
fi

echo "🚀 Launching Calendar Menu Bar App..."
open "$APP_BUNDLE"
