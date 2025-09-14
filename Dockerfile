# NVIDIA PyTorch Image mit Python 3.10 und CUDA
FROM nvcr.io/nvidia/pytorch:24.01-py3

# Systempakete installieren
RUN apt-get update && apt-get install -y \
    git wget ffmpeg sox libsox-dev libsox-fmt-all && \
    rm -rf /var/lib/apt/lists/*

# Python 3.10 erzwingen (falls das Image etwas Neueres mitbringt)
RUN apt-get update && apt-get install -y python3.10 python3.10-venv python3.10-dev && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# Arbeitsverzeichnis
WORKDIR /workspace

# Coqui-TTS klonen und installieren
RUN git clone https://github.com/coqui-ai/TTS.git && \
    cd TTS && \
    pip install -e .

# Configs-Verzeichnis vorbereiten
RUN mkdir -p /workspace/configs && \
    wget https://raw.githubusercontent.com/coqui-ai/TTS/main/TTS/configs/xtts_v2_adapter.json \
    -O /workspace/configs/xtts_v2_adapter.json

# Datenstruktur für Sprecher anlegen
RUN mkdir -p /workspace/data/speaker1 \
    && mkdir -p /workspace/data/speaker2 \
    && mkdir -p /workspace/data/speaker3

COPY data/ /workspace/data/

# Standard-Startbefehl: Bash
CMD ["/bin/bash"]

