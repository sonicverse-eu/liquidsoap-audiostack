# liquidsoap-audiostack

[![CI](https://github.com/Sonicverse-EU/liquidsoap-audiostack/actions/workflows/ci.yml/badge.svg)](https://github.com/Sonicverse-EU/liquidsoap-audiostack/actions/workflows/ci.yml)
[![Docker Image](https://github.com/Sonicverse-EU/liquidsoap-audiostack/actions/workflows/docker.yml/badge.svg)](https://github.com/Sonicverse-EU/liquidsoap-audiostack/actions/workflows/docker.yml)

This repository contains a professional-grade audio streaming solution originally built for [ZuidWest FM](https://www.zuidwestfm.nl/). But also used by Sonicverse for [Breeze Radio](https://breezeradio.nl).

- **High-availability streaming** with automatic failover between multiple inputs
- **Multiple output formats**: Icecast streaming (MP3/AAC)
- **Docker-based deployment** for easy installation and management

While originally designed for these three Dutch radio stations, the system is fully configurable for any radio station's needs.


## System Design

The system delivers audio through dual redundant pathways. Liquidsoap prioritizes the main input (Icecast 1). If it becomes unavailable or silent, the system automatically switches to Icecast 2. Should both inputs fail, it falls back to an emergency audio file (configured via `EMERGENCY_AUDIO_PATH`). For maximum reliability, both inputs should receive the same broadcast via separate network paths.

### Components

1. **Liquidsoap**: Core audio processing engine - handles input switching, fallback logic, and encoding
2. **Icecast**: Public streaming server for distributing MP3/AAC streams to listeners

## Getting Started

### Requirements

- Linux server (Ubuntu 24.04 or Debian 12 recommended)
- Docker and Docker Compose installed
- x86_64 or ARM64 architecture
- At least 2GB RAM and 10GB disk space
- Network connectivity for SRT streams

### Quick Install

```bash
# Install Liquidsoap
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Sonicverse-EU/liquidsoap-audiostack/main/install.sh)"
```

### Configuration

After installation, edit the environment file at `/opt/liquidsoap/.env` to configure your station settings. Example configuration files are provided:

- `.env.breeze.example` - Basic configuration

Copy the appropriate example file to `.env` and customize it for your station. Most configuration variables are centralized in `conf/lib/defaults.liq`.


### Running with Docker

```bash
cd /opt/liquidsoap

# Start services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```


## Silence Detection

The system includes automatic silence detection that monitors studio inputs and manages fallback behavior. This feature is **enabled by default**.

### How it works

When silence detection is **enabled** (default):

- Studio inputs automatically switch away when silent for more than 15 seconds
- If both studios are silent/disconnected, the system plays the fallback file
- If no fallback file exists, the system plays silence
- Provides automatic redundancy for unattended operation

When silence detection is **disabled**:

- Studio inputs continue playing even when silent and only switch away when disconnected
- No automatic switching between sources
- Fallback file is never used
- Useful for testing or when manual control is preferred

### Configuration

Control silence detection via the control file:

```bash
# Enable silence detection (default)
echo '1' > /silence_detection.txt

# Disable silence detection
echo '0' > /silence_detection.txt
```

Note: The actual path depends on your container volume mapping. By default, this file is located at `/silence_detection.txt` inside the container.

Changes take effect immediately without restarting the service.

### Silence thresholds

The default silence detection parameters can be adjusted via environment variables:

- `SILENCE_SWITCH_SECONDS`: Maximum silence duration in seconds (default: 15.0)
- `AUDIO_VALID_SECONDS`: The minimum duration of continuous audio required for an input to be considered valid (default: 15.0)

## Streaming to SRT Inputs

The system accepts two SRT input streams:

- **Port 8888**: Primary studio input (Studio A)
- **Port 9999**: Secondary studio input (Studio B)

All connections require encryption using the passphrase configured in `SRT_PASSPHRASE`.





### Debug Commands

```bash
# View all logs
docker compose logs -f

# Check service status
docker compose ps

# Restart services
docker compose restart

# Validate configuration
docker run --rm -v "$PWD:/app" -w /app savonet/liquidsoap:latest liquidsoap -c conf/*.liq
```

## Development

### Building from Source

```bash
# Clone repository
git clone https://github.com/Sonicverse-EU/liquidsoap-audiostack.git
cd liquidsoap-audiostack

# Build Docker image
docker buildx build --platform linux/amd64,linux/arm64 -t liquidsoap-audiostack:local .

# Run with custom image
docker compose up -d
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run syntax validation: `docker run --rm -v "$PWD:/app" -w /app savonet/liquidsoap:latest liquidsoap -c conf/*.liq`
5. Submit a pull request

## License

Copyright 2025 Omroepstichting ZuidWest & Stichting BredaNu. This project is licensed under the MIT License. See [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Liquidsoap](https://www.liquidsoap.info/) - The amazing audio streaming language
- [Icecast](https://icecast.org/) - Reliable streaming server