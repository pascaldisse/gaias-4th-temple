#!/usr/bin/env python3
"""
Audio Frequency Analyzer for Hidden Messages
Analyzes M4A files for frequency patterns and potential encoded data
"""

import numpy as np
import subprocess
import sys
import os
from scipy.fft import fft, fftfreq
from scipy.signal import spectrogram, find_peaks
import base64
import matplotlib.pyplot as plt

def extract_audio_from_m4a(input_file):
    """Convert M4A to WAV using ffmpeg for analysis"""
    output_file = input_file.replace('.m4a', '_temp.wav')
    
    try:
        # Use ffmpeg to convert M4A to WAV
        cmd = [
            'ffmpeg', '-i', input_file,
            '-acodec', 'pcm_s16le',
            '-ar', '44100',
            '-ac', '2',
            '-y', output_file
        ]
        
        subprocess.run(cmd, check=True, capture_output=True)
        print(f"Converted {input_file} to WAV format")
        return output_file
    except subprocess.CalledProcessError as e:
        print(f"Error converting file: {e}")
        print("Make sure ffmpeg is installed: brew install ffmpeg")
        return None
    except FileNotFoundError:
        print("ffmpeg not found. Install with: brew install ffmpeg")
        return None

def read_wav_data(wav_file):
    """Read WAV file and return audio data"""
    import wave
    
    with wave.open(wav_file, 'rb') as wav:
        # Get audio parameters
        channels = wav.getnchannels()
        sample_width = wav.getsampwidth()
        framerate = wav.getframerate()
        n_frames = wav.getnframes()
        
        print(f"Audio info: {channels} channels, {framerate} Hz, {n_frames} frames")
        
        # Read audio data
        audio_data = wav.readframes(n_frames)
        
        # Convert to numpy array
        if sample_width == 2:  # 16-bit audio
            audio_array = np.frombuffer(audio_data, dtype=np.int16)
        else:
            audio_array = np.frombuffer(audio_data, dtype=np.int8)
            
        # Reshape for stereo
        if channels == 2:
            audio_array = audio_array.reshape(-1, 2)
            # Use left channel for analysis
            audio_array = audio_array[:, 0]
            
        return audio_array.astype(np.float32), framerate

def analyze_frequencies(audio_data, sample_rate):
    """Perform frequency analysis using FFT"""
    print("\n=== Frequency Analysis ===")
    
    # Compute FFT
    n = len(audio_data)
    yf = fft(audio_data)
    xf = fftfreq(n, 1/sample_rate)
    
    # Get magnitude spectrum
    magnitude = np.abs(yf[:n//2])
    frequencies = xf[:n//2]
    
    # Find peak frequencies
    peaks, properties = find_peaks(magnitude, height=np.max(magnitude)*0.1)
    peak_freqs = frequencies[peaks]
    peak_mags = magnitude[peaks]
    
    print(f"\nTop 10 peak frequencies:")
    sorted_peaks = sorted(zip(peak_freqs, peak_mags), key=lambda x: x[1], reverse=True)[:10]
    for freq, mag in sorted_peaks:
        print(f"  {freq:.1f} Hz (magnitude: {mag:.0f})")
    
    # Check for ultrasonic content (potential hidden data)
    ultrasonic = frequencies > 15000
    ultrasonic_power = np.sum(magnitude[ultrasonic])
    total_power = np.sum(magnitude)
    
    if ultrasonic_power / total_power > 0.01:
        print(f"\n⚠️  Ultrasonic content detected! ({ultrasonic_power/total_power*100:.1f}% of total power)")
        print("This could indicate hidden data in high frequencies")
    
    return frequencies, magnitude

def detect_steganography_patterns(audio_data, sample_rate):
    """Look for common steganography patterns"""
    print("\n=== Steganography Detection ===")
    
    # Check LSB (Least Significant Bit) patterns
    lsb_bits = audio_data.astype(np.int16) & 1
    lsb_changes = np.diff(lsb_bits)
    lsb_change_rate = np.sum(np.abs(lsb_changes)) / len(lsb_bits)
    
    print(f"LSB change rate: {lsb_change_rate:.3f}")
    if lsb_change_rate > 0.45 and lsb_change_rate < 0.55:
        print("⚠️  Suspicious LSB pattern detected (near 50% change rate)")
    
    # Check for phase encoding
    analytic_signal = np.imag(np.fft.hilbert(audio_data))
    phase_changes = np.diff(np.angle(analytic_signal))
    unusual_phases = np.sum(np.abs(phase_changes) > np.pi/2) / len(phase_changes)
    
    if unusual_phases > 0.1:
        print(f"⚠️  Unusual phase patterns detected ({unusual_phases*100:.1f}% large phase jumps)")
    
    # Extract potential bits from LSB
    message_bits = []
    for i in range(0, min(len(lsb_bits), 1024), 8):
        byte_bits = lsb_bits[i:i+8]
        if len(byte_bits) == 8:
            message_bits.append(byte_bits)
    
    return message_bits

def decode_potential_messages(audio_data, message_bits):
    """Try to decode potential hidden messages"""
    print("\n=== Message Extraction Attempts ===")
    
    # Method 1: Direct LSB to ASCII
    if message_bits:
        ascii_chars = []
        for byte_bits in message_bits[:128]:  # First 128 bytes
            byte_val = sum(bit * (2**i) for i, bit in enumerate(byte_bits))
            if 32 <= byte_val <= 126:  # Printable ASCII
                ascii_chars.append(chr(byte_val))
        
        if len(ascii_chars) > 10:
            potential_msg = ''.join(ascii_chars)
            print(f"Potential LSB message: {potential_msg[:100]}...")
            
            # Try base64 decode
            try:
                # Clean up potential base64
                clean_b64 = ''.join(c for c in potential_msg if c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=')
                if len(clean_b64) > 4:
                    decoded = base64.b64decode(clean_b64[:len(clean_b64)//4*4])
                    if decoded:
                        print(f"Base64 decoded: {decoded[:100]}")
            except:
                pass
    
    # Method 2: Frequency domain encoding
    # Check specific frequency bins that might encode data
    fft_data = np.fft.fft(audio_data[:8192])
    high_freq_bins = np.abs(fft_data[4000:4100])  # Around 10-11kHz for 44.1kHz sample rate
    
    if np.max(high_freq_bins) > np.mean(high_freq_bins) * 5:
        print("⚠️  Suspicious frequency spikes detected in 10-11kHz range")

def visualize_analysis(audio_data, sample_rate, frequencies, magnitude):
    """Create visualization of the analysis"""
    fig, axes = plt.subplots(3, 1, figsize=(12, 10))
    
    # Waveform
    time = np.arange(len(audio_data)) / sample_rate
    axes[0].plot(time[:sample_rate*5], audio_data[:sample_rate*5])  # First 5 seconds
    axes[0].set_title('Waveform (first 5 seconds)')
    axes[0].set_xlabel('Time (s)')
    axes[0].set_ylabel('Amplitude')
    
    # Frequency spectrum
    axes[1].semilogy(frequencies[:10000], magnitude[:10000])
    axes[1].set_title('Frequency Spectrum')
    axes[1].set_xlabel('Frequency (Hz)')
    axes[1].set_ylabel('Magnitude')
    axes[1].grid(True)
    
    # Spectrogram
    f, t, Sxx = spectrogram(audio_data[:sample_rate*10], sample_rate, nperseg=1024)
    axes[2].pcolormesh(t, f[:1000], 10 * np.log10(Sxx[:1000, :]), shading='gouraud')
    axes[2].set_ylabel('Frequency [Hz]')
    axes[2].set_xlabel('Time [sec]')
    axes[2].set_title('Spectrogram (first 10 seconds)')
    
    plt.tight_layout()
    output_file = 'audio_analysis.png'
    plt.savefig(output_file)
    print(f"\nVisualization saved to {output_file}")
    plt.close()

def main():
    # Audio file path
    audio_file = "/Users/pascaldisse/gaia/gaias-4th-oracle/Danziger Straße 123.m4a"
    
    print("=== Gaia Audio Frequency Analyzer ===")
    print(f"Analyzing: {audio_file}")
    
    if not os.path.exists(audio_file):
        print(f"Error: File not found at {audio_file}")
        return
    
    # Convert M4A to WAV
    wav_file = extract_audio_from_m4a(audio_file)
    if not wav_file:
        return
    
    try:
        # Read audio data
        audio_data, sample_rate = read_wav_data(wav_file)
        
        # Analyze frequencies
        frequencies, magnitude = analyze_frequencies(audio_data, sample_rate)
        
        # Check for steganography
        message_bits = detect_steganography_patterns(audio_data, sample_rate)
        
        # Try to decode messages
        decode_potential_messages(audio_data, message_bits)
        
        # Create visualizations
        visualize_analysis(audio_data, sample_rate, frequencies, magnitude)
        
        print("\n=== Analysis Complete ===")
        print("Check audio_analysis.png for visual results")
        
    finally:
        # Clean up temporary WAV file
        if os.path.exists(wav_file):
            os.remove(wav_file)

if __name__ == "__main__":
    main()