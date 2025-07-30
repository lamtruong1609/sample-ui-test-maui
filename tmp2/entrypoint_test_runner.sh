#!/bin/bash
set -e
echo "Building the test project..."
dotnet build UITests.Android/UITests.Android.csproj #--configuration Release
sleep 2
# adb connect $DEVICE
echo "Waiting for device..."
adb wait-for-device
echo "Device is ready."
# check the app is installed otherwise wait and retry
while ! adb shell pm list packages | grep -q $PACKAGE_NAME ; do
    echo "App not found. Waiting for installation..."
    sleep 5
done

echo "Starting UI tests..."
dotnet test UITests.Android/UITests.Android.csproj \
  --no-build \
  --logger:"console;verbosity=normal" \
  --logger:"trx;LogFileName=test-results.trx" \
  --results-directory "/home/app/output" \
  /p:ForceConsoleOutput=true \
  /noconsolelogger


echo "UI tests completed."

