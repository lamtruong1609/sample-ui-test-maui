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

# Accept licenses
RUN yes | $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --licenses || (cat $HOME/.android/adb.log || true; exit 1)

# Install platform tools
RUN $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager "platform-tools" || (cat $HOME/.android/adb.log || true; exit 1)

# Install platforms
RUN $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager "platforms;android-33" || (cat $HOME/.android/adb.log || true; exit 1)

# Install build tools
RUN $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager "build-tools;33.0.2" || (cat $HOME/.android/adb.log || true; exit 1)

# Install emulator
RUN $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager "emulator" || (cat $HOME/.android/adb.log || true; exit 1)

# Install system image
RUN $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager "system-images;android-33;google_apis;arm64-v8a" || (cat $HOME/.android/adb.log || true; exit 1)

# Update SDK
RUN $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --update || (cat $HOME/.android/adb.log || true; exit 1)

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