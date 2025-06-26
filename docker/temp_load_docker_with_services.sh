#!/bin/bash
# Enhanced thermal management script with Docker service control

TEMP_THRESHOLD=${TEMP_THRESHOLD:-91}  # Celsius - can be set via environment
CHECK_INTERVAL=${CHECK_INTERVAL:-30}  # seconds - can be set via environment
COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-"thermal"}  # Docker compose project name
SERVICES_TO_CONTROL=${SERVICES_TO_CONTROL:-"system-monitor"}  # Comma-separated list of services

echo "Enhanced thermal management started:"
echo "- Temperature threshold: ${TEMP_THRESHOLD}°C"
echo "- Check interval: ${CHECK_INTERVAL}s" 
echo "- Compose project: ${COMPOSE_PROJECT_NAME}"
echo "- Services to control: ${SERVICES_TO_CONTROL}"

# Convert comma-separated services to array
IFS=',' read -ra SERVICE_ARRAY <<< "$SERVICES_TO_CONTROL"

# Track service states to avoid unnecessary operations
declare -A SERVICE_STATES
for service in "${SERVICE_ARRAY[@]}"; do
    SERVICE_STATES[$service]="running"
done

# Function to check if service is running
is_service_running() {
    local service_name="$1"
    local container_name="${COMPOSE_PROJECT_NAME}-${service_name}-1"
    docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"
}

# Function to stop a service
stop_service() {
    local service_name="$1"
    echo "$(date): DOCKER: Stopping service '${service_name}' due to high temperature"
    if docker compose stop "$service_name" 2>/dev/null; then
        SERVICE_STATES[$service_name]="stopped"
        echo "$(date): DOCKER: Successfully stopped '${service_name}'"
        return 0
    else
        echo "$(date): DOCKER: Failed to stop '${service_name}'"
        return 1
    fi
}

# Function to start a service
start_service() {
    local service_name="$1"
    echo "$(date): DOCKER: Starting service '${service_name}' - temperature normalized"
    if docker compose start "$service_name" 2>/dev/null; then
        SERVICE_STATES[$service_name]="running"
        echo "$(date): DOCKER: Successfully started '${service_name}'"
        return 0
    else
        echo "$(date): DOCKER: Failed to start '${service_name}'"
        return 1
    fi
}

while true; do
    # Get CPU temperature
    TEMP=$(sensors 2>/dev/null | grep 'temp1:' | head -1 | awk '{print $2}' | sed 's/+//g' | sed 's/°C//g' | cut -d'.' -f1)
    
    # Check if TEMP is a valid number
    if [ -z "$TEMP" ] || ! echo "$TEMP" | grep -q '^[0-9][0-9]*$'; then
        echo "$(date): Error: Could not read temperature. Got: '$TEMP'"
        sleep $CHECK_INTERVAL
        continue
    fi
    
    # Get current governor
    CURRENT_GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
    
    if [ -z "$CURRENT_GOVERNOR" ]; then
        echo "$(date): Error: Could not read current CPU governor"
        sleep $CHECK_INTERVAL
        continue
    fi
    
    if [ "$TEMP" -gt "$TEMP_THRESHOLD" ]; then
        # Temperature too high - thermal throttling actions
        echo "$(date): HIGH TEMPERATURE ALERT: ${TEMP}°C (threshold: ${TEMP_THRESHOLD}°C)"
        
        # Set conservative CPU governor
        if [ "$CURRENT_GOVERNOR" != "powersave" ]; then
            if echo powersave > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null; then
                echo "$(date): CPU: Changed to powersave mode (was $CURRENT_GOVERNOR)"
            else
                echo "$(date): CPU: Failed to change to powersave mode"
            fi
        fi
        
        # Stop specified Docker services if running
        for service in "${SERVICE_ARRAY[@]}"; do
            service=$(echo "$service" | xargs)  # trim whitespace
            if [ "${SERVICE_STATES[$service]}" = "running" ]; then
                stop_service "$service"
            else
                echo "$(date): DOCKER: Service '${service}' already stopped"
            fi
        done
        
    else
        # Temperature OK - restore normal operation
        echo "$(date): Temperature normal: ${TEMP}°C"
        
        # Set normal CPU governor
        if [ "$CURRENT_GOVERNOR" != "ondemand" ]; then
            if echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null; then
                echo "$(date): CPU: Changed to ondemand mode (was $CURRENT_GOVERNOR)"
            else
                echo "$(date): CPU: Failed to change to ondemand mode"
            fi
        fi
        
        # Start specified Docker services if stopped
        for service in "${SERVICE_ARRAY[@]}"; do
            service=$(echo "$service" | xargs)  # trim whitespace
            if [ "${SERVICE_STATES[$service]}" = "stopped" ]; then
                start_service "$service"
            fi
        done
    fi
    
    sleep $CHECK_INTERVAL
done