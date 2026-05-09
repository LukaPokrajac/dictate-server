# dictate-server

Push-to-talk voice dictation for Linux/Wayland — hold the middle mouse button, speak, release to paste.

The whisper model stays loaded in VRAM between recordings, so transcription is near-instant instead of paying a cold-start cost on every press.
## Architecture

```
Middle button held → pw-record → whisper-ptt → HTTP POST → whisper-server → JSON
                                                                             ↓
                                                 wl-copy + wtype ← text
```

- `whisper-server` — whisper.cpp HTTP server, model in VRAM, listens on `127.0.0.1:9001`
- `whisper-ptt` — PTT daemon, grabs the mouse exclusively (no clipboard side-effects), sends audio via POST to `/inference`

## Requirements

- Linux with Wayland
- GPU with [Vulkan](https://vulkan.lunarg.com/) support (tested on AMD, works on NVIDIA/Intel)
- `python-evdev` — mouse input capture
- `pipewire` — audio recording (`pw-record`)
- `wl-clipboard` — clipboard write (`wl-copy`)
- `wtype` — keystroke injection

Install dependencies (Arch/Manjaro):

```bash
sudo pacman -S python-evdev pipewire wl-clipboard wtype
```

Ubuntu/Debian:

```bash
sudo apt install python3-evdev pipewire wl-clipboard wtype
```

## Setup

### 1. Build whisper.cpp with Vulkan

```bash
git clone https://github.com/ggerganov/whisper.cpp ~/whisper.cpp
cd ~/whisper.cpp
cmake -B build -DGGML_VULKAN=1
cmake --build build --config Release -j$(nproc)
```

### 2. Download a model

```bash
cd ~/whisper.cpp
bash models/download-ggml-model.sh large-v3-turbo
```

Any model works — `large-v3-turbo` is the best balance of speed and accuracy. Smaller options: `medium`, `small`, `base`.

### 3. Add yourself to the `input` group

Required once so the daemon can grab mouse events without root:

```bash
sudo usermod -aG input $USER
# Log out and back in for this to take effect
```

### 4. Install

```bash
git clone https://github.com/LukaPokrajac/dictate-server
cd dictate-server
bash install.sh
```

If whisper.cpp is not at `~/whisper.cpp`, pass the path explicitly:

```bash
bash install.sh /path/to/whisper.cpp
```

## Configuration

### Changing the PTT button

Edit `whisper-ptt` and change `PTT_BUTTON` near the top of the file:

```python
PTT_BUTTON = 'BTN_MIDDLE'  # or BTN_RIGHT, BTN_SIDE, BTN_EXTRA, ...
```

Then reinstall: `bash install.sh`

### Adjusting silence detection

If transcription triggers on ambient noise, raise `RMS_THRESHOLD` in `whisper-ptt`:

```python
RMS_THRESHOLD = 400  # increase to 600-800 for noisier environments
```

### Changing the model or whisper.cpp path

Edit `~/.config/systemd/user/whisper-server.service` directly and update the `ExecStart` line, then:

```bash
systemctl --user restart whisper-server
```

### Running whisper-server on a different port

Edit `~/.config/systemd/user/whisper-server.service` (`--port`) and set `WHISPER_SERVER` in `whisper-ptt`:

```python
WHISPER_SERVER = 'http://127.0.0.1:9001/inference'  # match the port above
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

## Troubleshooting

**`No mouse devices with middle button found`** — you haven't been added to the `input` group yet, or haven't logged out and back in since adding. Verify with `groups`.

**`whisper-server not reachable at 127.0.0.1:9001`** — whisper-server failed to start. Check: `journalctl --user -u whisper-server -b` for the error (most likely the binary or model path is wrong in the service file).

**Transcription is always empty / silence detected** — try lowering `RMS_THRESHOLD` or check that `pw-record` is capturing audio from the right source (`pactl list sources short`).

**Middle-click still pastes** — the daemon is not running or failed to grab the device. Check `journalctl --user -u whisper-ptt -f`.
