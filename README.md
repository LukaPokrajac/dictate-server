# dictate-server

Push-to-talk diktiranje glasom — whisper model stalno učitan u VRAM.

Fork od [dictate](https://github.com/LukaPokrajac/dictate) sa HTTP serverom umjesto direktnog poziva `whisper-cli`. Model se učita jednom pri startu i ostaje u memoriji, svaka transkripcija je znatno brža.

## Arhitektura

```
Ctrl+Space → pw-record → whisper-ptt → HTTP POST → whisper-server → JSON
                                                                      ↓
                                              wl-copy + wtype ← text
```

- `whisper-server` — whisper.cpp HTTP server, model u VRAM, sluša na `127.0.0.1:9001`
- `whisper-ptt` — PTT daemon, audio šalje POST-om na `/inference`

## Zavisnosti

- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) buildan sa Vulkan backendom (`whisper-server` binary)
- Model `ggml-large-v3-turbo.bin` na `/home/pokr/whisper.cpp/models/`
- `python-evdev`, `pipewire` (`pw-record`), `wl-clipboard` (`wl-copy`), `wtype`

## Instalacija

```bash
# Dodaj sebe u input grupu (jedanput, zahtijeva logout)
sudo usermod -aG input $USER

# Instaliraj daemon i servise
bash install.sh
```

## Upravljanje

```bash
# Status
systemctl --user status whisper-server whisper-ptt

# Logovi
journalctl --user -u whisper-server -f
journalctl --user -u whisper-ptt -f

# Restart
systemctl --user restart whisper-server whisper-ptt
```
