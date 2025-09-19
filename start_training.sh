#!/bin/bash
set -e

echo "🔹 Starte Setup für XTTS v2 Voice Cloning..."

# 1) System-Pakete
apt-get update -qq && apt-get install -y \
  git wget ffmpeg sox libsox-dev libsox-fmt-all \
  python3.11 python3.11-venv python3.11-dev \
  && rm -rf /var/lib/apt/lists/*

# 2) Virtuelle Umgebung erstellen
cd /workspace
python3.11 -m venv tts-env
source tts-env/bin/activate

# 3) Pip upgraden
pip install --upgrade pip setuptools wheel

# 4) Coqui-TTS (idiap Fork, main Branch)
if [ ! -d "TTS" ]; then
  git clone https://github.com/idiap/coqui-ai-TTS.git TTS
fi
cd TTS
git pull
git checkout main
pip install -e .[all]

# 5) Eigene Anforderungen installieren
cd /workspace
pip install -r requirements_all.txt || true

# 6) Daten kopieren (aus Repo → Workspace)
mkdir -p /workspace/data
cp -r /root/my-voice-project/data/* /workspace/data/ || true
cp -r /root/my-voice-project/configs/* /workspace/configs/ || true

# 7) Testlauf: TTS Version + Modelldownload
python - <<'EOF'
from TTS.api import TTS
print("✅ TTS Version:", __import__('TTS').__version__)
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2", gpu=True)
print("✅ XTTS v2 geladen!")
EOF

echo "🎉 Setup abgeschlossen! Aktiviere die venv mit:"
echo "source /workspace/tts-env/bin/activate"
