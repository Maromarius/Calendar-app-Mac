# Calendar Menu Bar App

A beautiful macOS menu bar application that displays all 12 months of the year when clicked.

## Features

- 📅 Shows all 12 months in a beautiful grid layout
- 🎨 Modern design with gradients and smooth styling
- 📍 Highlights the current month
- 📆 Mini calendar view for each month showing actual days
- 🖱️ Click the calendar icon in the menu bar to show/hide
- 🎯 Lightweight menu bar app (no dock icon)

## Requirements

- macOS 11.0 or later
- Xcode Command Line Tools (for Swift compiler)

## Installation

### Build from source:

1. Open Terminal and navigate to this directory
2. Make the build script executable:
   ```bash
   chmod +x build.sh run.sh
   ```

3. Build the app:
   ```bash
   ./build.sh
   ```

4. Run the app:
   ```bash
   ./run.sh
   ```

### Install to Applications folder (optional):

After building, copy the app to your Applications folder:
```bash
cp -r build/CalendarMenuBar.app /Applications/
```

Then launch it from Applications or Spotlight.

## Usage

1. After launching, look for the calendar icon (📅) in your menu bar
2. Click the icon to show all 12 months of the current year
3. The current month will be highlighted in blue
4. Click outside the calendar or click the icon again to close it

## Files

- `CalendarApp.swift` - Main application entry point
- `AppDelegate.swift` - Menu bar icon and popover management
- `CalendarViewController.swift` - View controller for the calendar
- `CalendarView.swift` - Custom view that renders the 12-month calendar
- `Info.plist` - App configuration (sets LSUIElement for menu bar only)
- `build.sh` - Build script to compile the app
- `run.sh` - Script to launch the app

## Development

The app is built with:
- Swift
- AppKit (native macOS framework)
- Custom drawing with Core Graphics

## License

Free to use and modify as needed.
