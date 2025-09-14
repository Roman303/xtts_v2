#!/bin/bash
set -e
# Pfade anpassen falls nötig
CONFIG="/workspace/configs/xtts_v2_adapter.json"
LOGDIR="/workspace/output_adaptation/logs"
mkdir -p $LOGDIR

CUDA_VISIBLE_DEVICES=0 python /workspace/TTS/TTS/bin/train_tts.py \
  --config_path $CONFIG 2>&1 | tee $LOGDIR/train_$(date +%Y%m%d_%H%M%S).log
