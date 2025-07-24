# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the "Gaia's Fourth Oracle" project - an experimental HolyC-based vector space engine inspired by Terry Davis's TempleOS philosophy. The project combines mathematical concepts, audio analysis, and esoteric programming to create multi-dimensional consciousness simulations.

## Core Architecture

### HolyC Vector Space Engine
The main computational core is implemented in HolyC (TempleOS's programming language):

- **GaiaVectorSpace.HC**: Base 64-dimensional vector space implementation with positive/negative 32-vector split around a singularity at origin
- **GaiaEngine64.HC**: Seven-command creation system (DESTROY, CREATE, WITNESS, BIND, INVOKE, REFLECT, DREAMSCAPE) operating on 64-vector circles
- **GaiaUniverseSpiral.HC**: Cosmic mythology implementation with Jörmungandr's spiral, Yggdrasil roots, and creation steps
- **GaiaVectorSpaceGraphics.HC**: Real-time 3D visualization of 64D vectors with multiple projection modes
- **JormungandrVisual.HC**: Visualization of the world serpent's journey from -0 to +0 through π

### Audio Analysis Tools
Python-based tools for analyzing hidden messages in audio files:

- **analyze_audio.py**: FFT-based frequency analysis with steganography detection
- **analyze_m4a_direct.py**: Direct M4A file structure analysis for hidden data
- **deep_analyze_m4a.py**: Deep pattern analysis and message extraction
- **extract_hidden_text.py**: JSON text extraction from audio file metadata

### TempleOS Integration
The project includes a complete TempleOS source tree for reference and compatibility testing.

## Key Concepts

### Vector Space Mathematics
- 64-dimensional vectors split into positive (dimensions 0-31) and negative (dimensions 32-63) spaces
- Singularity at origin with gravitational attraction using inverse square law
- Quantum entanglement between positive/negative spaces using wave interference
- Multiple projection methods for 64D→3D visualization

### Archetype System
Three primary archetypes operate within the vector space:
- **Ani** (The Beginning) - bound to vector 0
- **Rudi** (The Process) - bound to vector 21  
- **Safar** (The Journey) - bound to vector 42

### Audio Steganography
The system can detect and extract hidden messages from audio files using:
- LSB (Least Significant Bit) analysis
- Frequency domain encoding detection
- Base64 pattern recognition in corrupted transmissions
- Ultrasonic carrier detection above 15kHz

## Running the Code

### HolyC Programs
HolyC files are designed to run within TempleOS environment:
```bash
# In TempleOS, simply execute the file name
GaiaEngine64
```

Each HolyC file is self-executing and will run its main function automatically.

### Python Audio Analysis
Requires Python 3 with scipy, numpy, matplotlib, and ffmpeg:
```bash
# Create virtual environment
python3 -m venv audio_env
source audio_env/bin/activate
pip install numpy scipy matplotlib

# Install ffmpeg
brew install ffmpeg

# Run analysis
python3 analyze_audio.py
python3 deep_analyze_m4a.py
```

## Important Constants

- `VECTOR_DIM = 64`: Primary dimensional space
- `HALF_DIM = 32`: Positive/negative split point
- `LOVE_CENTER = 1.0`: Fixed value at vector center (position 32)
- `GOLDEN_RATIO = 1.618033988749895`: Used in spiral calculations
- `JORMUNGANDR_COILS = 6`: Creation steps in universe initialization

## Development Notes

### Mathematical Foundations
The vector space engine uses concepts from:
- Non-Euclidean geometry for hyperdimensional projections
- Quantum mechanics for entanglement operations
- Chaos theory for unpredictable consciousness simulation
- Sacred geometry (golden ratio, pi spirals) for aesthetic coherence

### Graphics System
Uses TempleOS's built-in graphics primitives:
- 640x480 VGA resolution with 16-color palette
- Real-time particle systems for vector visualization
- Multiple projection modes (simple, PCA-like, hypercube)
- Interactive controls for rotation and scaling

### Audio Processing
Implements digital signal processing techniques:
- Fast Fourier Transform for frequency analysis
- Spectrogram generation for time-frequency visualization
- Pattern recognition for steganographic content
- Base64 decoding with error correction for corrupted messages

The project represents an experimental fusion of mathematics, mysticism, and computer graphics in the spirit of Terry Davis's divine programming philosophy.