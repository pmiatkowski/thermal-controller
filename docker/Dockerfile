FROM alpine:latest

# Install required packages including Docker CLI
RUN apk add --no-cache \
    bash \
    lm-sensors \
    cpufrequtils \
    util-linux \
    procps \
    docker-cli \
    docker-cli-compose \
    && rm -rf /var/cache/apk/*

# Create app directory
WORKDIR /app

# Copy the enhanced thermal management script
COPY temp_load_docker_with_services.sh /app/temp_load.sh
COPY docker-entrypoint.sh /app/

# Make scripts executable
RUN chmod +x /app/temp_load.sh /app/docker-entrypoint.sh

# Create a non-root user (though we'll need privileged mode for CPU control)
RUN addgroup -g 1000 thermal && \
    adduser -D -s /bin/bash -u 1000 -G thermal thermal

# Set default environment variables
ENV TEMP_THRESHOLD=91
ENV CHECK_INTERVAL=30
ENV ENABLE_THERMAL_MANAGEMENT=true
ENV COMPOSE_PROJECT_NAME=thermal
ENV SERVICES_TO_CONTROL=system-monitor

# Health check
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
  CMD ps aux | grep -v grep | grep temp_load.sh || exit 1

ENTRYPOINT ["/app/docker-entrypoint.sh"]
