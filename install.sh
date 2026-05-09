#!/usr/bin/env bash
set -e

WHISPER_DIR="${1:-$HOME/whisper.cpp}"

if [ ! -f "$WHISPER_DIR/build/bin/whisper-server" ]; then
    echo "Error: whisper-server binary not found at $WHISPER_DIR/build/bin/whisper-server"
    echo ""
    echo "Build whisper.cpp with Vulkan support first:"
    echo "  cd $WHISPER_DIR && cmake -B build -DGGML_VULKAN=1 && cmake --build build --config Release"
    echo ""
    echo "Usage: bash install.sh [/path/to/whisper.cpp]"
    echo "  Default: \$HOME/whisper.cpp"
    exit 1
fi

MODEL=$(ls "$WHISPER_DIR/models/ggml-large-v3-turbo.bin" 2>/dev/null || ls "$WHISPER_DIR/models/"ggml-*.bin 2>/dev/null | head -1 || true)

if [ -z "$MODEL" ]; then
    echo "Error: no model found in $WHISPER_DIR/models/"
    echo ""
    echo "Download a model first, e.g.:"
    echo "  cd $WHISPER_DIR && bash models/download-ggml-model.sh large-v3-turbo"
    exit 1
fi

echo "Using whisper.cpp at: $WHISPER_DIR"
echo "Using model:          $MODEL"

sudo cp whisper-ptt /usr/local/bin/whisper-ptt
sudo chmod +x /usr/local/bin/whisper-ptt

mkdir -p ~/.config/systemd/user

sed "s|%h/whisper\.cpp/build/bin/whisper-server|$WHISPER_DIR/build/bin/whisper-server|g; \
     s|%h/whisper\.cpp/models/ggml-large-v3-turbo\.bin|$MODEL|g" \
    whisper-server.service > ~/.config/systemd/user/whisper-server.service

cp whisper-ptt.service ~/.config/systemd/user/whisper-ptt.service

systemctl --user daemon-reload
systemctl --user enable whisper-server whisper-ptt
systemctl --user start whisper-server whisper-ptt

echo ""
echo "Done. Service status:"
systemctl --user status whisper-server whisper-ptt --no-pager
