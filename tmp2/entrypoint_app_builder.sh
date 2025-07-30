#!/bin/bash
set -e

# DEVICE=127.0.0.1:5555

# Path to the APK file (update this path as needed)
APK_PATH=$(ls /home/app/publish/*-Signed.apk 2>/dev/null | head -n 1)

# Check if APK file exists
if [ -z "$APK_PATH" ] || [ ! -f "$APK_PATH" ]; then
    echo "APK file not found in /home/app/publish/"
    exit 1
fi
# Ensure emulator is reachable
echo "Connecting ADB to emulator..."
adb connect 127.0.0.1:5555

# Wait until the package manager is available
MAX_RETRIES=60
RETRY=0
while ! adb shell pm path android >/dev/null 2>&1; do
    RETRY=$((RETRY+1))
    if [ $RETRY -ge $MAX_RETRIES ]; then
        echo "No device connected or package manager unavailable after $MAX_RETRIES attempts."
        exit 2
    fi
    echo "Waiting for package manager to become available... ($RETRY/$MAX_RETRIES)"
    sleep 5
done

# Additional checks to ensure system is fully ready
echo "Package manager available. Waiting for system to be fully ready..."
SYSTEM_READY=false
SYSTEM_RETRY=0
MAX_SYSTEM_RETRIES=30

while [ "$SYSTEM_READY" = false ] && [ $SYSTEM_RETRY -lt $MAX_SYSTEM_RETRIES ]; do
    SYSTEM_RETRY=$((SYSTEM_RETRY+1))
    
    # Check if settings provider is available
    if adb shell settings list system >/dev/null 2>&1; then
        echo "Settings provider is available."
        
        # Check if system is fully booted
        BOOT_COMPLETED=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
        if [ "$BOOT_COMPLETED" = "1" ]; then
            echo "System boot completed."
            
            # Additional check for package installer readiness
            if adb shell dumpsys package | grep -q "Packages:"; then
                echo "Package installer is ready."
                SYSTEM_READY=true
            else
                echo "Package installer not ready yet... ($SYSTEM_RETRY/$MAX_SYSTEM_RETRIES)"
            fi
        else
            echo "System still booting... ($SYSTEM_RETRY/$MAX_SYSTEM_RETRIES)"
        fi
    else
        echo "Settings provider not available yet... ($SYSTEM_RETRY/$MAX_SYSTEM_RETRIES)"
    fi
    
    if [ "$SYSTEM_READY" = false ]; then
        sleep 10
    fi
done

if [ "$SYSTEM_READY" = false ]; then
    echo "System not ready after $MAX_SYSTEM_RETRIES attempts. Exiting."
    exit 3
fi

# Install the app using adb with retry logic
echo "Installing APK: $APK_PATH"
INSTALL_RETRY=0
MAX_INSTALL_RETRIES=3

while [ $INSTALL_RETRY -lt $MAX_INSTALL_RETRIES ]; do
    INSTALL_RETRY=$((INSTALL_RETRY+1))
    echo "Installation attempt $INSTALL_RETRY/$MAX_INSTALL_RETRIES"
    
    if adb install -r "$APK_PATH"; then
        echo "Installation complete."
        break
    else
        echo "Installation failed on attempt $INSTALL_RETRY"
        if [ $INSTALL_RETRY -lt $MAX_INSTALL_RETRIES ]; then
            echo "Waiting 10 seconds before retry..."
            sleep 10
        else
            echo "Installation failed after $MAX_INSTALL_RETRIES attempts."
            exit 4
        fi
    fi
done