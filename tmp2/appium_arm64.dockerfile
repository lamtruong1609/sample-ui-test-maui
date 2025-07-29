FROM arm64v8/openjdk:17-slim

ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=$ANDROID_SDK_ROOT
ENV ANDROID_EMULATOR_WAIT_TIME_BEFORE_KILL=60
ENV PATH=${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:$PATH

# Install dependencies
RUN apt-get update && apt-get install -y wget unzip && \
    rm -rf /var/lib/apt/lists/*

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

# Accept licenses and install Android packages
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --licenses && \
    ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager \
        "platform-tools" \
        "platforms;android-34" \
        "build-tools;34.0.0" \
        "emulator" \
        "system-images;android-34;google_apis;arm64-v8a"

# Install Appium
RUN apt-get update && apt-get install -y nodejs npm && \
    npm install -g appium && \
    rm -rf /var/lib/apt/lists/*

# Start Appium
CMD ["appium", "--allow-insecure", "chromedriver_autodownload"]