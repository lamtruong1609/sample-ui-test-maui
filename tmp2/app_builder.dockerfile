FROM mcr.microsoft.com/dotnet/sdk:9.0.203 AS builder

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip wget openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Set environment paths for Android SDK
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=${ANDROID_SDK_ROOT}
ENV PATH="${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools"

# Download and install Android command line tools
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    cd ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O tools.zip && \
    unzip tools.zip -d temp && \
    mv temp/cmdline-tools latest && \
    rm tools.zip

# Ensure sdkmanager is executable
RUN chmod +x ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager

# Debug: Check Java version and sdkmanager
RUN java -version && \
    ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --version && \
    ls -l ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/

# Accept Android licenses
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --licenses --sdk_root=${ANDROID_SDK_ROOT} || true

# Install SDK packages with fallback to Android 34 if Android 35 is unavailable
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} \
        "platform-tools" \
        "platforms;android-35" \
        "build-tools;35.0.0" \
        "emulator" \
        "system-images;android-35;google_apis;arm64-v8a" || \
    yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} \
        "platform-tools" \
        "platforms;android-34" \
        "build-tools;34.0.0" \
        "emulator" \
        "system-images;android-34;google_apis;arm64-v8a"

# Install .NET MAUI Android workload
RUN dotnet workload install maui-android

# Set working directory
WORKDIR /home/app

# Copy project files
COPY BasicAppiumNunitSample/MauiApp /home/app
RUN dotnet publish BasicAppiumNunitSample.csproj -f net9.0-android -c Release -o ./publish 

# Copy entrypoint script
COPY entrypoint_app_builder.sh /home/app/entrypoint.sh
ENTRYPOINT ["/home/app/entrypoint.sh"]