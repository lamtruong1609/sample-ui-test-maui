FROM mcr.microsoft.com/dotnet/sdk:9.0.203 AS builder

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    android-tools-adb \
    && rm -rf /var/lib/apt/lists/*

# Environment configuration to prevent noisy logs and ensure stability
ENV TERM=xterm
ENV COLUMNS=120
ENV LINES=30
ENV MSBUILD_TERMINAL_LOGGER=off
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Set working directory
WORKDIR /home/app

# Copy the test source files
COPY BasicAppiumNunitSample/ /home/app

# Copy entrypoint script
COPY entrypoint_test_runner.sh /home/app/entrypoint.sh

# Make sure output directory exists
RUN mkdir -p /home/app/output

# Grant execution permission for entrypoint
RUN chmod +x /home/app/entrypoint.sh

ENTRYPOINT ["/home/app/entrypoint.sh"]
