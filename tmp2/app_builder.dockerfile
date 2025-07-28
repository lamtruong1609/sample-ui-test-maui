FROM mcr.microsoft.com/dotnet/sdk:9.0.203 AS builder

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip wget openjdk-17-jdk \
    libc6-dev libgcc1 libncurses5 libstdc++6 zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Set environment paths for Android SDK
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=$ANDROID_SDK_ROOT
ENV PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools"

# Download and install Android command line tools (correct structure)
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    cd $ANDROID_SDK_ROOT/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O tools.zip && \
    unzip tools.zip && \
    mv cmdline-tools latest && \
    rm tools.zip

# Verify SDK manager is accessible
RUN ls -la $ANDROID_SDK_ROOT/cmdline-tools/latest/bin && \
    $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --list || true

# Accept licenses and install packages (using direct path)
RUN yes | $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --licenses && \
    $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager \
        "platform-tools" \
        "platforms;android-33" \
        "build-tools;33.0.2" \
        "emulator" \
        "system-images;android-33;google_apis;arm64-v8a" && \
    $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --update

# Install .NET MAUI Android workload
RUN dotnet workload install maui-android && \
    dotnet workload install android

WORKDIR /home/app
COPY BasicAppiumNunitSample/MauiApp /home/app

# Build for ARM64 architecture
RUN dotnet publish BasicAppiumNunitSample.csproj \
    -f net9.0-android \
    -c Release \
    -o ./publish \
    -p:AndroidSupportedAbis=arm64-v8a \
    -p:AndroidArch=arm64-v8a

COPY entrypoint_app_builder.sh /home/app/entrypoint.sh
ENTRYPOINT ["/home/app/entrypoint.sh"]