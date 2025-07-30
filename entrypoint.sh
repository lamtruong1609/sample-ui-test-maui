#!/bin/bash
set -e

echo "Building the MAUI app..."
dotnet build BasicAppiumNunitSample/MauiApp/BasicAppiumNunitSample.csproj -c Release

echo "Publishing the MAUI app..."
dotnet publish BasicAppiumNunitSample/MauiApp/BasicAppiumNunitSample.csproj -f net9.0-android -c Release -o ./publish

echo "Waiting for device..."
adb wait-for-device
echo "Device is ready."

echo "Installing the APK to device..."
# Find the APK and install it
APK_PATH=$(find ./publish -name "*.apk" | head -n 1)
if [ -z "$APK_PATH" ]; then
    echo "Error: No APK found in ./publish directory"
    exit 1
fi

echo "Installing APK: $APK_PATH"
adb install -r "$APK_PATH"

echo "Waiting for app installation..."
sleep 5

# Check if the app is installed
while ! adb shell pm list packages | grep -q $PACKAGE_NAME ; do
    echo "App not found. Waiting for installation..."
    sleep 5
done

echo "App is installed. Building the test project..."
dotnet build UITests.Android/UITests.Android.csproj
sleep 2

echo "Starting UI tests..."
dotnet test UITests.Android/UITests.Android.csproj \
  --no-build \
  --logger:"console;verbosity=normal" \
  --logger:"trx;LogFileName=test-results.trx" \
  --results-directory "/home/app/output" \
  /p:ForceConsoleOutput=true \
  /noconsolelogger

echo "UI tests completed." 