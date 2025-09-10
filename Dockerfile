# Basis: offizielles PyTorch mit CUDA 12.8 + CUDNN 9
FROM pytorch/pytorch:2.5.1-cuda12.8-cudnn9-runtime

# Systempakete
RUN apt-get update && apt-get install -y \
    git ffmpeg sox build-essential python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Pip aktualisieren
RUN pip install --upgrade pip setuptools wheel

# Fix für Cython (Coqui TTS braucht < 3.0)
RUN pip install cython==0.29.36

# Coqui-TTS klonen und installieren
RUN git clone https://github.com/coqui-ai/TTS.git /workspace/TTS
WORKDIR /workspace/TTS
RUN pip install -e .

# Zusatz: Sounddateien und nützliche Pakete
RUN pip install soundfile librosa
