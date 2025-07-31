# #!/bin/bash
# set -e

# echo "=== MAUI Android Test Workflow ==="

# # Function to check if emulator is ready
# check_emulator_ready() {
#     echo "Checking if emulator is ready..."
#     if adb devices | grep -q "emulator"; then
#         BOOT_COMPLETED=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
#         if [ "$BOOT_COMPLETED" = "1" ]; then
#             echo "✅ Emulator is ready!"
#             return 0
#         else
#             echo "⏳ Emulator still booting..."
#             return 1
#         fi
#     else
#         echo "❌ No emulator found"
#         return 1
#     fi
# }

# # Step 1: Start emulator and Appium
# echo "Step 1: Starting Android emulator and Appium..."
# docker-compose -f docker-compose.emulator.yml up -d

# echo "Waiting for emulator to start..."
# sleep 30

# # Step 2: Wait for emulator to be ready
# echo "Step 2: Waiting for emulator to be ready..."
# MAX_WAIT=600  # 10 minutes
# WAIT_COUNT=0

# while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
#     if check_emulator_ready; then
#         break
#     fi
#     WAIT_COUNT=$((WAIT_COUNT + 10))
#     echo "Waiting... ($WAIT_COUNT/$MAX_WAIT seconds)"
#     sleep 10
# done

# if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
#     echo "❌ Emulator failed to start within $MAX_WAIT seconds"
#     exit 1
# fi

# # Step 3: Wait for Appium to be ready
# echo "Step 3: Waiting for Appium to be ready..."
# sleep 10

# # Step 4: Run the tests
# echo "Step 4: Running tests..."
# docker-compose up app-builder

# echo "=== Test workflow completed ==="

# # Optional: Keep emulator and Appium running for debugging
# echo "Emulator and Appium are still running. To stop them, run:"
# echo "docker-compose -f docker-compose.emulator.yml down" 