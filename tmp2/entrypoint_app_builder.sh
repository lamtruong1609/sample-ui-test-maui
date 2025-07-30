#!/bin/bash
set -e

# Path to the APK file (auto-detected)
APK_PATH=$(ls /home/app/publish/*-Signed.apk 2>/dev/null | head -n 1)

# Check if APK exists
if [ -z "$APK_PATH" ] || [ ! -f "$APK_PATH" ]; then
    echo "❌ APK file not found in /home/app/publish/"
    exit 1
fi

echo "✅ Found APK: $APK_PATH"

# Connect to emulator if not already connected
if adb devices | grep -q "emulator-5554[[:space:]]*device"; then
    echo "✅ Emulator already connected via emulator-5554."
else
    echo "🔌 Connecting ADB to emulator..."
    adb connect 127.0.0.1:5555 || {
        echo "❌ Failed to connect to emulator via ADB."
        exit 1
    }
fi


# Wait for package manager to be available
echo "⏳ Waiting for package manager..."
for i in {1..60}; do
    if adb shell pm path android >/dev/null 2>&1; then
        echo "✅ Package manager is available."
        break
    fi
    echo "Waiting for package manager... ($i/60)"
    sleep 5
    if [ $i -eq 60 ]; then
        echo "❌ Timeout waiting for package manager."
        exit 2
    fi
done

# Wait for system readiness
echo "⏳ Waiting for system boot completion and package installer..."
for i in {1..30}; do
    BOOT_COMPLETED=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
    if [ "$BOOT_COMPLETED" == "1" ]; then
        echo "✅ System boot completed."

        if adb shell settings list system >/dev/null 2>&1 && \
           adb shell dumpsys package | grep -q "Packages:"; then
            echo "✅ System services and package installer are ready."
            break
        else
            echo "System still initializing... ($i/30)"
        fi
    else
        echo "System not yet booted... ($i/30)"
    fi

    sleep 10
    if [ $i -eq 30 ]; then
        echo "❌ System did not become ready in time."
        exit 3
    fi
done

# Install APK with retries
echo "⬇️ Installing APK..."
for i in {1..3}; do
    if adb install -r "$APK_PATH"; then
        echo "✅ APK installed successfully."
        exit 0
    else
        echo "⚠️ Install failed (attempt $i/3)"
        sleep 10
    fi
done

echo "❌ Failed to install APK after 3 attempts."
exit 4
