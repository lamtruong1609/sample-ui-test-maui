FROM mcr.microsoft.com/dotnet/sdk:9.0.203 AS builder

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip openjdk-17-jdk wget zip \
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

# Verify sdkmanager is accessible
RUN ls -la ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin && \
    ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --version

# Accept licenses and install necessary Android packages
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --licenses && \
    ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager \
        "platform-tools" \
        "platforms;android-34" \
        "build-tools;34.0.0" \
        "emulator" \
        "system-images;android-34;google_apis;arm64-v8a"

# Install .NET MAUI Android workload
RUN dotnet workload install maui-android

# Set working directory
WORKDIR /home/app

# Copy your MAUI app source code
COPY BasicAppiumNunitSample/MauiApp/ /home/app/

# Publish the MAUI Android app
RUN dotnet publish BasicAppiumNunitSample.csproj \
    -f net9.0-android \
    -c Release \
    -o /home/app/publish \
    -p:AndroidSupportedAbis=arm64-v8a

# Copy and configure entrypoint script
COPY entrypoint_app_builder.sh /home/app/entrypoint.sh
RUN chmod +x /home/app/entrypoint.sh

# Start from entrypoint
ENTRYPOINT ["/home/app/entrypoint.sh"]