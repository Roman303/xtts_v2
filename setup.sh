#!/bin/bash
# Aktualisieren und Pakete installieren
apt-get update && apt-get install -y git ffmpeg python3-pip
# Repo klonen
git clone https://github.com/Roman303/xtts_v2.git /workspace/xtts
cd /workspace/xtts
pip install -r requirements.txt
