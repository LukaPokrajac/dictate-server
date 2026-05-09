# dictate-server

Push-to-talk voice dictation — whisper model permanently loaded in VRAM.

Fork of [dictate](https://github.com/LukaPokrajac/dictate) with an HTTP server instead of direct `whisper-cli` invocation. The model loads once at startup and stays in memory, making each transcription significantly faster.

## Architecture

```
Ctrl+Space → pw-record → whisper-ptt → HTTP POST → whisper-server → JSON
                                                                     ↓
                                             wl-copy + wtype ← text
```

- `whisper-server` — whisper.cpp HTTP server, model in VRAM, listens on `127.0.0.1:9001`
- `whisper-ptt` — PTT daemon, sends audio via POST to `/inference`

## Dependencies

- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) built with Vulkan backend (`whisper-server` binary)
- Model `ggml-large-v3-turbo.bin` at `/home/pokr/whisper.cpp/models/`
- `python-evdev`, `pipewire` (`pw-record`), `wl-clipboard` (`wl-copy`), `wtype`

## Installation

```bash
# Add yourself to the input group (once, requires logout)
sudo usermod -aG input $USER

# Install daemon and services
bash install.sh
```

## Management

```bash
# Status
systemctl --user status whisper-server whisper-ptt

# Logs
journalctl --user -u whisper-server -f
journalctl --user -u whisper-ptt -f

# Restart
systemctl --user restart whisper-server whisper-ptt
```
