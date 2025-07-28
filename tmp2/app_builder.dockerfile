FROM mcr.microsoft.com/dotnet/sdk:9.0.203 AS builder

# Install Java and other dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    wget \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=$ANDROID_SDK_ROOT
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${JAVA_HOME}/bin:${PATH}"

# Create SDK directory and download command line tools
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    cd ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O tools.zip && \
    unzip tools.zip && \
    mv cmdline-tools latest && \
    rm tools.zip

# Ensure sdkmanager is executable
RUN chmod +x ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager

# Debug: Verify Java and sdkmanager setup
RUN echo "Checking Java installation..." && \
    java -version || { echo "Java installation failed"; exit 1; } && \
    echo "Checking sdkmanager installation..." && \
    ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --version || { echo "sdkmanager failed"; exit 1; }

# Accept licenses and install SDK components
RUN yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --licenses && \
    ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager \
        "platform-tools" \
        "platforms;android-33" \
        "build-tools;33.0.2" \
        "emulator" \
        "system-images;android-33;google_apis;arm64-v8a"

# Install .NET MAUI workload
RUN dotnet workload install maui-android

# Install Appium
RUN apt-get update && apt-get install -y --no-install-recommends nodejs npm && \
    npm install -g appium && \
    rm -rf /var/lib/apt/lists/*

# Build the application
WORKDIR /home/app
COPY BasicAppiumNunitSample /home/app/BasicAppiumNunitSample
WORKDIR /home/app/BasicAppiumNunitSample
RUN dotnet publish BasicAppiumNunitSample.csproj -f net9.0-android -c Release -o ./publish

# Entry point
COPY entrypoint_app_builder.sh /home/app/entrypoint.sh
RUN chmod +x /home/app/entrypoint.sh
ENTRYPOINT ["/home/app/entrypoint.sh"]