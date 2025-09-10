#!/bin/bash
# Beendet das Skript bei Fehlern
set -eo pipefail

# Wechselt in das Arbeitsverzeichnis
cd /workspace/

# Klont dein Repository
git clone https://github.com/Roman303/xtts_v2.git
cd xtts_v2

# Aktiviert die virtuelle Umgebung (falls vorhanden, ansonsten anpassen)
. /venv/main/bin/activate

# Installiert Abhängigkeiten (z. B. aus requirements.txt)
pip install -r requirements.txt

# Weitere Einrichtungsbefehle (an dein Projekt anpassen)
# Beispiel: wget -P /workspace/ https://example.com/meine-datei.tar.gz
# tar xvf /workspace/meine-datei.tar.gz
