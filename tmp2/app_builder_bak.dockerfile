FROM mcr.microsoft.com/dotnet/sdk:9.0.203 AS builder

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip wget openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=$ANDROID_SDK_ROOT
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools"

# Install Android command-line tools
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    cd ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O tools.zip && \
    unzip tools.zip && \
    mv cmdline-tools latest && \
    rm tools.zip

# Debug: Check if sdkmanager exists
RUN ls -la ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/ || echo "Directory not found"

# Install Android SDK components
RUN ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses || (echo "License acceptance failed" && exit 1)

RUN ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" || (echo "platform-tools installation failed" && exit 1)

RUN ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platforms;android-34" || (echo "platforms installation failed" && exit 1)

RUN ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "build-tools;34.0.0" || (echo "build-tools installation failed" && exit 1)

RUN ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "emulator" || (echo "emulator installation failed" && exit 1)

RUN ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "system-images;android-34;google_apis;x86_64" || (echo "system-images installation failed" && exit 1)

RUN dotnet workload install maui-android

WORKDIR /home/app
COPY BasicAppiumNunitSample/MauiApp /home/app

# Debug: Check Android SDK installation
RUN ls -la ${ANDROID_SDK_ROOT}/platforms/ || echo "Platforms directory not found"
RUN ls -la ${ANDROID_SDK_ROOT}/build-tools/ || echo "Build tools directory not found"

# Debug: Check if project file exists
RUN ls -la /home/app/ || echo "App directory not found"
RUN ls -la /home/app/*.csproj || echo "Project file not found"

# Debug: Check Android SDK environment
RUN echo "ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
RUN echo "ANDROID_HOME: $ANDROID_HOME"
RUN ls -la $ANDROID_SDK_ROOT/ || echo "Android SDK root not found"

# Debug: Check if Android SDK components are actually installed
RUN find ${ANDROID_SDK_ROOT} -name "*.jar" | head -5 || echo "No JAR files found"
RUN find ${ANDROID_SDK_ROOT} -name "android.jar" || echo "android.jar not found"

# Add AndroidSdkDirectory to the project file
RUN sed -i '/<PropertyGroup>/a \    <AndroidSdkDirectory>$(ANDROID_SDK_ROOT)</AndroidSdkDirectory>' /home/app/BasicAppiumNunitSample.csproj

# Try building with the modified project file
RUN dotnet publish /home/app/BasicAppiumNunitSample.csproj -f net9.0-android -c Release -o ./publish

COPY entrypoint_app_builder.sh /home/app/entrypoint.sh
RUN chmod +x /home/app/entrypoint.sh
ENTRYPOINT ["/home/app/entrypoint.sh"]
