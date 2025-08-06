FROM mcr.microsoft.com/dotnet/sdk:9.0.203 AS builder

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip wget openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=$ANDROID_SDK_ROOT
ENV PATH="${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools"

RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    cd ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O tools.zip && \
    unzip tools.zip && \
    mv cmdline-tools latest && \
    rm tools.zip


RUN yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses && \
    sdkmanager --sdk_root=${ANDROID_SDK_ROOT} \
        "platform-tools" \
        "platforms;android-35" \
        "build-tools;35.0.0" \
        "emulator" \
        "system-images;android-35;google_apis;x86_64"

RUN dotnet workload install maui-android

WORKDIR /home/app
COPY BasicAppiumNunitSample/MauiApp /home/app
RUN dotnet publish BasicAppiumNunitSample.csproj -f net9.0-android -c Release -o ./publish

COPY entrypoint_app_builder.sh /home/app/entrypoint.sh
RUN chmod +x /home/app/entrypoint.sh
ENTRYPOINT ["/home/app/entrypoint.sh"]
