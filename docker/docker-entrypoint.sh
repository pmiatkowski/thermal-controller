#!/bin/bash

# Docker entrypoint script for thermal management

echo "=== Thermal Management Container Starting ==="
echo "Temperature threshold: ${TEMP_THRESHOLD}°C"
echo "Check interval: ${CHECK_INTERVAL}s"
echo "Thermal management enabled: ${ENABLE_THERMAL_MANAGEMENT}"

# Check if thermal management is enabled
if [ "${ENABLE_THERMAL_MANAGEMENT}" != "true" ]; then
    echo "Thermal management is disabled. Container will sleep indefinitely."
    echo "To enable, set ENABLE_THERMAL_MANAGEMENT=true"
    sleep infinity
fi

# Verify we have access to required system files
if [ ! -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
    echo "ERROR: Cannot access CPU frequency scaling files."
    echo "Make sure the container is running in privileged mode with /sys mounted."
    exit 1
fi

# Check if sensors command works
if ! command -v sensors >/dev/null 2>&1; then
    echo "ERROR: sensors command not found."
    exit 1
fi

# Test temperature reading
echo "Testing temperature sensor..."
TEMP_TEST=$(sensors 2>/dev/null | grep 'temp1:' | head -1 | awk '{print $2}' | sed 's/+//g' | sed 's/°C//g' | cut -d'.' -f1)
if [ -z "$TEMP_TEST" ] || ! echo "$TEMP_TEST" | grep -q '^[0-9][0-9]*$'; then
    echo "WARNING: Cannot read temperature sensor. Current reading: '$TEMP_TEST'"
    echo "The script will continue but may not work properly."
else
    echo "Temperature sensor working. Current temp: ${TEMP_TEST}°C"
fi

# Check available CPU governors
echo "Available CPU governors:"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "Could not read available governors"

echo "Current CPU governor:"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "Could not read current governor"

echo "=== Starting thermal management script ==="

# Export environment variables for the script
export TEMP_THRESHOLD
export CHECK_INTERVAL

# Start the thermal management script
exec /app/temp_load.sh
