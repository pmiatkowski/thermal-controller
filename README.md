# Enhanced Thermal Management with Docker Service Control

This enhanced thermal management system not only controls CPU frequency scaling based on temperature but also automatically stops/starts specified Docker services when temperature exceeds the threshold.

## Why This Service Exists

This thermal management service was specifically created for devices that operate in challenging outdoor environments where temperature control is critical. The primary use case is for devices deployed in:

- **High-temperature outdoor locations** during summer months
- **Direct sunlight exposure** where solar heating significantly raises device temperature
- **Environments with no active cooling** (no fans, air conditioning, or other cooling systems)
- **Remote monitoring setups** where physical access for manual intervention is limited

In these scenarios, the device can quickly overheat, potentially causing:

- CPU throttling and performance degradation
- System instability or crashes
- Hardware damage from prolonged high temperatures
- Service interruptions for critical monitoring tasks

This automated thermal management system provides a proactive solution by intelligently reducing system load (stopping non-critical services) and implementing CPU frequency scaling to prevent overheating while maintaining system stability.

## Directory Structure

```
thermal/
├── docker-compose.yml          # Main compose configuration
├── README.md                   # This documentation
└── docker/                     # Docker-related files
    ├── Dockerfile              # Container image definition
    ├── docker-entrypoint.sh    # Container startup script
    └── temp_load_docker_with_services.sh  # Enhanced thermal script
```

## How It Works

When CPU temperature > 91°C (configurable):

1. **CPU Throttling**: Changes CPU governor to `powersave` mode
2. **Service Control**: Stops specified Docker services to reduce system load
3. **Monitoring**: Continuously monitors temperature

When temperature normalizes (≤ 91°C):

1. **CPU Recovery**: Changes CPU governor back to `ondemand` mode  
2. **Service Restart**: Automatically restarts previously stopped services

## Quick Start

1. **Configure services to control** (edit `thermal.env`):

   ```bash
   # Stop system-monitor and example-service when overheated
   SERVICES_TO_CONTROL=system-monitor,example-service
   
   # Or stop no services (CPU throttling only)
   SERVICES_TO_CONTROL=
   
   # Or control your actual services
   SERVICES_TO_CONTROL=motioneye,other-service
   ```

2. **Start the thermal management system**:

   ```bash
   docker compose up -d
   ```

3. **Monitor thermal management logs**:

   ```bash
   docker logs -f thermal-manager
   ```

## Configuration Options

Edit `thermal.env` to customize behavior:

- `TEMP_THRESHOLD=91` - Temperature threshold in Celsius
- `CHECK_INTERVAL=30` - How often to check temperature (seconds)  
- `SERVICES_TO_CONTROL=service1,service2` - Which services to stop when hot
- `ENABLE_THERMAL_MANAGEMENT=true` - Enable/disable thermal management

## Available Services in Current Compose

- `thermal-manager` - The thermal management service itself (never stopped)
- `system-monitor` - Node exporter for system monitoring (can be stopped)
- `example-service` - Example nginx service (can be stopped)

To control your own services:

1. Add them to this docker-compose.yml
2. Add their names to `SERVICES_TO_CONTROL` in `docker-compose.yml`

## Troubleshooting

**Services not being controlled:**

- Check service names match exactly: `docker ps`
- Verify Docker socket access: `docker exec thermal-manager docker ps`
- Check logs: `docker logs thermal-manager`

**Temperature not reading:**

- Ensure `lm-sensors` is configured on host: `sensors-detect`
- Check sensor output: `sensors`

**CPU governor not changing:**

- Verify privileged mode is enabled
- Check available governors: `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors`

## Integration with Existing Services

To integrate with your existing docker-compose setup:

1. **Move your services into this compose file**, or
2. **Use Docker networks** to connect compose files, or  
3. **Copy the thermal-manager service** to your existing compose file

Example integration:

```yaml
# In your existing docker-compose.yml
services:
  your-service:
    # ... your config ...
    networks:
      - thermal_monitoring
      
networks:
  thermal_monitoring:
    external: true
    name: thermal_monitoring
```

## Author

**Paweł Miatkowski**

- GitHub: [@pmiatkowski](https://github.com/pmiatkowski)
- Repository: [thermal-controller](https://github.com/pmiatkowski/thermal-controller)

## License

This project is licensed under the ISC License.

### ISC License

Copyright (c) 2025, Paweł Miatkowski

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an Issue on the [GitHub repository](https://github.com/pmiatkowski/thermal-controller).
