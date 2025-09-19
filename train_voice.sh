#!/bin/bash
set -e

echo "🔹 Starte XTTS v2 Voice Cloning Training..."

# 1) Virtuelle Umgebung aktivieren
if [ -f "/workspace/tts-env/bin/activate" ]; then
  source /workspace/tts-env/bin/activate
else
  echo "❌ Virtuelle Umgebung nicht gefunden. Bitte zuerst start_training.sh ausführen!"
  exit 1
fi

# 2) Trainings-Config vorbereiten
CONFIG_PATH="/workspace/configs/xtts_v2_adapter.json"
mkdir -p /workspace/configs

cat > $CONFIG_PATH <<EOL
{
  "model": "XTTSAdapter",
  "run_name": "my_voice_clone",
  "batch_size": 4,
  "eval_batch_size": 4,
  "num_loader_workers": 2,
  "num_eval_loader_workers": 2,
  "epochs": 10,
  "text_cleaner": "multilingual_cleaners",
  "use_phonemes": false,
  "phoneme_language": "de",
  "phoneme_cache_path": "/workspace/output_adaptation/phoneme_cache",
  "output_path": "/workspace/output_adaptation",
  "audio": {
    "sample_rate": 24000,
    "channels": 1,
    "fft_size": 1024,
    "hop_length": 256,
    "win_length": 1024,
    "mel_fmin": 0,
    "mel_fmax": 8000
  },
  "data": {
    "datasets": [
      {
        "name": "my_voice",
        "path": "/workspace/data/speaker1",
        "meta_file_train": "/workspace/data/speakers_all.csv"
      }
    ]
  },
  "training": {
    "optimizer": "adam",
    "learning_rate": 0.0001,
    "grad_clip": 1.0,
    "mixed_precision": true
  },
  "restore_path": "tts_models/multilingual/multi-dataset/xtts_v2"
}
EOL

echo "✅ Trainings-Config erstellt unter: $CONFIG_PATH"

# 3) CSV-Datei prüfen
if [ ! -f "/workspace/data/speakers_all.csv" ]; then
  echo "❌ speakers_all.csv fehlt!"
  echo "Bitte eine CSV erstellen mit folgendem Format:"
  echo "filepath|text|speaker_name"
  exit 1
fi

# 4) Training starten
cd /workspace/TTS
CUDA_VISIBLE_DEVICES=0 python TTS/bin/train_tts.py --config_path $CONFIG_PATH

echo "🎉 Training abgeschlossen! Ergebnisse liegen in /workspace/output_adaptation"
