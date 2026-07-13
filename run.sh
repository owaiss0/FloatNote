#!/bin/bash
# Build and run the macOS FloatNote app in the background

echo "Building FloatNote..."
swift build --sdk $(xcrun --show-sdk-path)

if [ $? -eq 0 ]; then
    echo "Starting FloatNote in background..."
    # Launch in background
    BIN_PATH=$(swift build --show-bin-path)
    "$BIN_PATH/FloatNote" &
    echo "FloatNote is running! Look for the note icon in your macOS Menu Bar."
else
    echo "Failed to build FloatNote."
fi
