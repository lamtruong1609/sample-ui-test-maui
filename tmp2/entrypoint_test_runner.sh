#!/bin/bash
set -e

echo "📦 Building test project..."
dotnet build UITests.Android/UITests.Android.csproj

echo "🔌 Waiting for device..."
adb wait-for-device

echo "📱 Device is ready."

RETRY=0
MAX_RETRIES=10

while ! adb shell pm list packages | grep -q "$PACKAGE_NAME"; do
    RETRY=$((RETRY + 1))
    if [ $RETRY -ge $MAX_RETRIES ]; then
        echo "❌ App not found after $MAX_RETRIES attempts. Exiting."
        exit 1
    fi
    echo "⏳ App not found. Waiting for installation... ($RETRY/$MAX_RETRIES)"
    sleep 5
done

echo "✅ App is installed. Starting tests..."

dotnet test UITests.Android/UITests.Android.csproj \
  --no-build \
  --logger:"console;verbosity=normal" \
  --logger:"trx;LogFileName=test-results.trx" \
  --results-directory "/home/app/output" \
  /p:ForceConsoleOutput=true \
  /noconsolelogger

echo "🎉 UI tests completed successfully."
