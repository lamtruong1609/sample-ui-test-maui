FROM mcr.microsoft.com/dotnet/sdk:9.0.203 AS builder

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip openjdk-17-jdk wget zip curl \
    && rm -rf /var/lib/apt/lists/*

# Set environment for Android SDK
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=$ANDROID_SDK_ROOT
ENV ANDROID_EMULATOR_WAIT_TIME_BEFORE_KILL=60
ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

# Download and setup Android command line tools (correct structure)
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    cd ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip && \
    unzip cmdline-tools.zip -d . && \
    mv cmdline-tools latest && \
    rm cmdline-tools.zip

# Debug: Check if sdkmanager exists and is executable
RUN ls -la ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/ && \
    echo "Testing sdkmanager version:" && \
    ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --version || echo "sdkmanager version failed"

# Debug: Test network connectivity
RUN echo "Testing network connectivity:" && \
    curl -I https://dl.google.com/android/repository/ || echo "Network test failed"

# Accept licenses first
RUN echo "y" | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --licenses || \
    (echo "License acceptance failed" && exit 1)

# Install packages one by one to identify which fails
# RUN echo "Installing platform-tools..." && \
#     ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager "platform-tools" || \
#     (echo "platform-tools installation failed" && exit 1)

# RUN echo "Installing platforms..." && \
#     ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager "platforms;android-33" || \
#     (echo "platforms installation failed" && exit 1)

# RUN echo "Installing build-tools..." && \
#     ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager "build-tools;33.0.2" || \
#     (echo "build-tools installation failed" && exit 1)

# RUN echo "Installing emulator..." && \
#     ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager "emulator" || \
#     (echo "emulator installation failed" && exit 1)

# # Try to install system image (this might fail on ARM64)
# RUN echo "Installing system image..." && \
#     ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager "system-images;android-33;google_apis;arm64-v8a" || \
#     (echo "system-image installation failed - this is expected on some ARM64 systems" && echo "Continuing without system image...")

# # Install .NET MAUI Android workload
# RUN dotnet workload install maui-android

# # Set working directory
# WORKDIR /home/app

# # Copy your MAUI app source code
# COPY BasicAppiumNunitSample/MauiApp/ /home/app/

# # Publish the MAUI Android app
# RUN dotnet publish BasicAppiumNunitSample.csproj \
#     -f net9.0-android \
#     -c Release \
#     -o /home/app/publish \
#     -p:AndroidSupportedAbis=arm64-v8a

# # Copy and configure entrypoint script
# COPY entrypoint_app_builder.sh /home/app/entrypoint.sh
# RUN chmod +x /home/app/entrypoint.sh

# # Start from entrypoint
# ENTRYPOINT ["/home/app/entrypoint.sh"]