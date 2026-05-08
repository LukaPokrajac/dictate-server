#!/usr/bin/env bash
set -e

sudo cp whisper-ptt /usr/local/bin/whisper-ptt
sudo chmod +x /usr/local/bin/whisper-ptt

mkdir -p ~/.config/systemd/user
cp whisper-server.service ~/.config/systemd/user/whisper-server.service
cp whisper-ptt.service ~/.config/systemd/user/whisper-ptt.service

systemctl --user daemon-reload
systemctl --user enable whisper-server whisper-ptt
systemctl --user start whisper-server whisper-ptt

echo "Done. Service status:"
systemctl --user status whisper-server whisper-ptt --no-pager
