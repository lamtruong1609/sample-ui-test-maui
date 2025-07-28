FROM mcr.microsoft.com/dotnet/sdk:9.0.203 AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip wget openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=$ANDROID_SDK_ROOT
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Download and set up Android command line tools
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    cd ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O tools.zip && \
    unzip tools.zip && \
    mv cmdline-tools latest && \
    rm tools.zip

# Set the correct path for sdkmanager
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# Debug: Print Java and sdkmanager version
RUN java -version && sdkmanager --version

# Accept licenses and install required SDK components (with verbose output)
RUN echo "y" | sdkmanager --licenses --verbose && \
    sdkmanager --verbose \
        "platform-tools" \
        "platforms;android-33" \
        "build-tools;33.0.2" \
        "emulator" \
        "system-images;android-33;google_apis;arm64-v8a"

# .NET MAUI workload
RUN dotnet workload install maui-android

# App copy and build
WORKDIR /home/app
COPY BasicAppiumNunitSample /home/app/BasicAppiumNunitSample
WORKDIR /home/app/BasicAppiumNunitSample
RUN dotnet publish BasicAppiumNunitSample.csproj -f net9.0-android -c Release -o ./publish

COPY entrypoint_app_builder.sh /home/app/entrypoint.sh
ENTRYPOINT ["/home/app/entrypoint.sh"]
