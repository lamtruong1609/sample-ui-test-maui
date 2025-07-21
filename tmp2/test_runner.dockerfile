FROM mcr.microsoft.com/dotnet/sdk:9.0.203 AS builder

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    android-tools-adb \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables to prevent terminal logger issues
ENV TERM=xterm
ENV COLUMNS=120
ENV LINES=30
ENV MSBUILD_TERMINAL_LOGGER=off
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

WORKDIR /home/app

COPY BasicAppiumNunitSample/ /home/app

# COPY global.json /home/app/
COPY entrypoint_test_runner.sh /home/app/entrypoint.sh

# Make sure the output directory exists
RUN mkdir -p /home/app/output

ENTRYPOINT ["/home/app/entrypoint.sh"]
