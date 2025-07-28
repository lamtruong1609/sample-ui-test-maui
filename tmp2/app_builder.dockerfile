FROM mcr.microsoft.com/dotnet/sdk:9.0.203 AS builder

# Install required packages including 32-bit compatibility libs for ARM emulation
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip wget openjdk-17-jdk \
    libc6-dev-i386 libgcc1:i386 libncurses5:i386 \
    libstdc++6:i386 zlib1g:i386 \
    && rm -rf /var/lib/apt/lists/*

# Set environment paths for Android SDK
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=$ANDROID_SDK_ROOT
ENV PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools"

# Download and install Android command line tools (updated version)
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    cd $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O tools.zip && \
    unzip tools.zip && \
    rm tools.zip

# Accept Android licenses and install SDK packages (ARM64 compatible)
RUN yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses && \
    sdkmanager --sdk_root=${ANDROID_SDK_ROOT} \
        "platform-tools" \
        "platforms;android-33" \  # Changed to 33 for better ARM64 support
        "build-tools;33.0.2" \   # Matching build tools version
        "emulator" \
        "system-images;android-33;google_apis;arm64-v8a" && \
    sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --update

# Install .NET MAUI Android workload with ARM64 support
RUN dotnet workload install maui-android && \
    dotnet workload install android

# Install QEMU for ARM emulation support
RUN apt-get update && apt-get install -y qemu-kvm && \
    rm -rf /var/lib/apt/lists/*

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