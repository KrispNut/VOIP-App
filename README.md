# Asterisk 16 - Docker SIP Server

A production-ready Asterisk 16 PBX Docker container configured for WebRTC and SIP calling, integrated with the VOIP-App Flutter softphone.

## Features

- **Asterisk 16** - Industry-standard open-source PBX
- **WebRTC Support** - WSS (WebSocket Secure) for browser/app-based calling
- **UDP/TCP Transport** - Legacy SIP client support
- **DTLS-SRTP** - Encrypted media via SRTP
- **Echo Test** - Extension 100 for audio testing

## Quick Start

```bash
make
```

## SIP Accounts

| Extension | Type | Password | Use Case |
|-----------|------|----------|----------|
| 300 | UDP | 300 | Linphone, CSipSimple, etc. |
| 400 | WebRTC | 400 | WebRTC clients |
| 500 | WebRTC | 500 | WebRTC clients |

## Extensions

| Extension | Description |
|-----------|-------------|
| 100 | Echo test (plays hello-world then echoes) |
| 300-999 | Dial any registered SIP extension |

## Configuration

### Required: Set Your Public IP

Edit `configuration/pjsip.conf` and replace `YOUR_PUBLIC_IP` with your server's public IP:

```ini
[transport-udp]
external_media_address=YOUR_PUBLIC_IP
external_signaling_address=YOUR_PUBLIC_IP
```

### Ports Exposed

| Port | Protocol | Service |
|-----|----------|---------|
| 5060 | UDP | SIP |
| 5060 | TCP | SIP |
| 8088 | TCP | HTTP (Asterisk REST API) |
| 8089 | TCP | WSS (WebRTC) |
| 30000-30100 | UDP | RTP Audio |

## VOIP-App Integration

### Server Settings in App

```
SIP Domain: <your-server-ip>
SIP Server: <your-server-ip>
Port: 5060

# For WebRTC (recommended)
WSS Server: wss://<your-server-ip>:8089/ws

# Account 500 example
SIP URI: 500@<your-server-ip>
Username: 500
Password: 500
Display Name: <your-name>
```

### Firewall Notes

If running locally for testing:
- Android Emulator: Use `10.0.2.2` to reach host localhost
- iOS Simulator: Use `127.0.0.1` or host IP
- Physical device: Use your machine's LAN IP

For production, ensure ports 5060, 8088, 8089, and 30000-30100 are open.

## Docker Commands

```bash
# Build image
docker build . -t asterisk16

# Run container
docker run --rm -it \
  -p 8088:8088/tcp \
  -p 8089:8089/tcp \
  -p 5060:5060/udp \
  -p 5060:5060/tcp \
  -p 30000-30100:30000-30100/udp \
  -v $(pwd)/configuration:/etc/asterisk \
  asterisk16
```