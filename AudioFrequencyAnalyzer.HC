// Audio Frequency Analyzer for Hidden Messages
// HolyC implementation for TempleOS
// Analyzes frequency patterns and decodes potential base64 messages

#define SAMPLE_RATE 44100
#define FFT_SIZE 1024
#define FREQ_BINS 512

// Audio data structures
class CAudioSample {
  F64 left;
  F64 right;
  U64 timestamp;
};

class CFrequencyBin {
  F64 frequency;
  F64 magnitude;
  F64 phase;
};

// Complex number for FFT
class CComplex {
  F64 real;
  F64 imag;
};

// Fast Fourier Transform implementation
U0 FFT(CComplex *data, I64 n, Bool inverse) {
  I64 i, j, k, l, m;
  CComplex w, u, t;
  F64 angle;
  
  // Bit reversal
  j = 0;
  for (i = 0; i < n; i++) {
    if (i < j) {
      t = data[i];
      data[i] = data[j];
      data[j] = t;
    }
    m = n / 2;
    while (j >= m && m > 0) {
      j -= m;
      m /= 2;
    }
    j += m;
  }
  
  // FFT computation
  l = 1;
  while (l < n) {
    m = l * 2;
    angle = (inverse ? 2.0 : -2.0) * π / m;
    w.real = Cos(angle);
    w.imag = Sin(angle);
    
    for (j = 0; j < l; j++) {
      u.real = 1.0;
      u.imag = 0.0;
      
      for (i = j; i < n; i += m) {
        k = i + l;
        
        // Butterfly operation
        t.real = u.real * data[k].real - u.imag * data[k].imag;
        t.imag = u.real * data[k].imag + u.imag * data[k].real;
        
        data[k].real = data[i].real - t.real;
        data[k].imag = data[i].imag - t.imag;
        
        data[i].real += t.real;
        data[i].imag += t.imag;
        
        // Update twiddle factor
        F64 temp = u.real;
        u.real = temp * w.real - u.imag * w.imag;
        u.imag = temp * w.imag + u.imag * w.real;
      }
    }
    l = m;
  }
  
  // Normalize for inverse FFT
  if (inverse) {
    for (i = 0; i < n; i++) {
      data[i].real /= n;
      data[i].imag /= n;
    }
  }
}

// Analyze frequency spectrum
U0 AnalyzeSpectrum(CAudioSample *samples, I64 sample_count, CFrequencyBin *bins) {
  CComplex fft_data[FFT_SIZE];
  I64 i, window_start;
  F64 window_val, magnitude;
  
  // Apply Hamming window and prepare FFT data
  for (window_start = 0; window_start < sample_count - FFT_SIZE; window_start += FFT_SIZE/2) {
    // Fill FFT buffer with windowed data
    for (i = 0; i < FFT_SIZE; i++) {
      window_val = 0.54 - 0.46 * Cos(2 * π * i / (FFT_SIZE - 1));
      fft_data[i].real = samples[window_start + i].left * window_val;
      fft_data[i].imag = 0.0;
    }
    
    // Perform FFT
    FFT(fft_data, FFT_SIZE, FALSE);
    
    // Extract frequency bins
    for (i = 0; i < FREQ_BINS; i++) {
      bins[i].frequency = i * SAMPLE_RATE / FFT_SIZE;
      magnitude = Sqrt(fft_data[i].real * fft_data[i].real + 
                      fft_data[i].imag * fft_data[i].imag);
      bins[i].magnitude = magnitude;
      bins[i].phase = Atan2(fft_data[i].imag, fft_data[i].real);
    }
  }
}

// Detect hidden patterns in frequency data
U0 DetectHiddenPatterns(CFrequencyBin *bins, I64 bin_count) {
  I64 i;
  F64 avg_magnitude = 0.0;
  F64 threshold;
  Bool anomaly_found = FALSE;
  
  // Calculate average magnitude
  for (i = 0; i < bin_count; i++) {
    avg_magnitude += bins[i].magnitude;
  }
  avg_magnitude /= bin_count;
  threshold = avg_magnitude * 3.0; // 3x average = anomaly
  
  Print("\n=== Hidden Pattern Detection ===\n");
  
  // Look for anomalous frequencies
  for (i = 0; i < bin_count; i++) {
    if (bins[i].magnitude > threshold) {
      Print("Anomaly at %f Hz (magnitude: %f)\n", 
            bins[i].frequency, bins[i].magnitude);
      anomaly_found = TRUE;
      
      // Check for common steganography frequencies
      if (bins[i].frequency >= 18000 && bins[i].frequency <= 20000) {
        Print("  >> Possible ultrasonic data carrier detected!\n");
      }
      if (bins[i].frequency >= 50 && bins[i].frequency <= 60) {
        Print("  >> Power line hum detected (possible timing signal)\n");
      }
    }
  }
  
  if (!anomaly_found) {
    Print("No obvious frequency anomalies detected.\n");
  }
}

// Base64 decoder for hidden messages
U8 Base64Decode(U8 ch) {
  if (ch >= 'A' && ch <= 'Z') return ch - 'A';
  if (ch >= 'a' && ch <= 'z') return ch - 'a' + 26;
  if (ch >= '0' && ch <= '9') return ch - '0' + 52;
  if (ch == '+') return 62;
  if (ch == '/') return 63;
  return 255; // Invalid
}

U0 DecodeBase64Message(U8 *encoded, U8 *decoded) {
  I64 i = 0, j = 0;
  U8 val[4];
  
  while (encoded[i]) {
    // Skip non-base64 characters
    if (Base64Decode(encoded[i]) == 255) {
      i++;
      continue;
    }
    
    // Collect 4 base64 characters
    I64 k;
    for (k = 0; k < 4 && encoded[i]; k++) {
      while (encoded[i] && Base64Decode(encoded[i]) == 255) i++;
      if (encoded[i]) {
        val[k] = Base64Decode(encoded[i++]);
      } else {
        val[k] = 0;
      }
    }
    
    // Decode to 3 bytes
    if (k >= 2) {
      decoded[j++] = (val[0] << 2) | (val[1] >> 4);
      if (k >= 3) {
        decoded[j++] = (val[1] << 4) | (val[2] >> 2);
        if (k >= 4) {
          decoded[j++] = (val[2] << 6) | val[3];
        }
      }
    }
  }
  decoded[j] = 0;
}

// Extract potential messages from frequency data
U0 ExtractMessagesFromFrequencies(CFrequencyBin *bins, I64 bin_count) {
  U8 potential_message[1024];
  U8 decoded_message[768];
  I64 i, msg_idx = 0;
  
  Print("\n=== Frequency-to-Message Extraction ===\n");
  
  // Method 1: High frequency bits
  for (i = 400; i < bin_count && msg_idx < 1023; i++) {
    if (bins[i].magnitude > 0.1) {
      // Convert phase to ASCII range
      U8 ch = (bins[i].phase + π) * 128 / (2 * π);
      if (ch >= 32 && ch <= 126) {
        potential_message[msg_idx++] = ch;
      }
    }
  }
  potential_message[msg_idx] = 0;
  
  if (msg_idx > 0) {
    Print("Potential phase-encoded message: %s\n", potential_message);
    
    // Try base64 decode
    DecodeBase64Message(potential_message, decoded_message);
    if (StrLen(decoded_message) > 0) {
      Print("Base64 decoded: %s\n", decoded_message);
    }
  }
  
  // Method 2: Magnitude patterns
  msg_idx = 0;
  for (i = 0; i < bin_count && msg_idx < 1023; i++) {
    if (bins[i].magnitude > 1.0) {
      // Quantize magnitude to ASCII
      U8 ch = 32 + (bins[i].magnitude * 10) % 95;
      potential_message[msg_idx++] = ch;
    }
  }
  potential_message[msg_idx] = 0;
  
  if (msg_idx > 0) {
    Print("Magnitude pattern: %s\n", potential_message);
  }
}

// Visualize frequency spectrum
U0 VisualizeSpectrum(CFrequencyBin *bins, I64 bin_count) {
  CDC *dc = DCAlias;
  I64 i;
  I32 x, y, bar_width;
  F64 max_magnitude = 0.0;
  
  // Find max magnitude for scaling
  for (i = 0; i < bin_count; i++) {
    if (bins[i].magnitude > max_magnitude) {
      max_magnitude = bins[i].magnitude;
    }
  }
  
  DCFill(dc);
  
  // Draw frequency spectrum
  dc->color = WHITE;
  GrPrint(dc, 5, 5, "Frequency Spectrum Analysis");
  GrPrint(dc, 5, 15, "Danziger Straße 123 Audio");
  
  bar_width = GR_WIDTH / bin_count;
  if (bar_width < 1) bar_width = 1;
  
  for (i = 0; i < bin_count && i < GR_WIDTH; i++) {
    x = i * bar_width;
    y = GR_HEIGHT - (bins[i].magnitude / max_magnitude * (GR_HEIGHT - 40));
    
    // Color based on frequency range
    if (bins[i].frequency < 250) {
      dc->color = RED;     // Bass
    } else if (bins[i].frequency < 2000) {
      dc->color = GREEN;   // Mids
    } else if (bins[i].frequency < 8000) {
      dc->color = BLUE;    // Highs
    } else {
      dc->color = YELLOW;  // Ultra-highs (possible data)
    }
    
    GrRect(dc, x, y, bar_width, GR_HEIGHT - y);
  }
  
  // Mark interesting frequencies
  dc->color = WHITE;
  GrPrint(dc, 5, GR_HEIGHT - 20, "0 Hz");
  GrPrint(dc, GR_WIDTH/2 - 20, GR_HEIGHT - 20, "11kHz");
  GrPrint(dc, GR_WIDTH - 40, GR_HEIGHT - 20, "22kHz");
  
  Sleep(3000);
  DCDel(dc);
}

// Simulate audio analysis (since we can't read the actual file)
U0 SimulateAudioAnalysis() {
  CAudioSample samples[SAMPLE_RATE];
  CFrequencyBin bins[FREQ_BINS];
  I64 i;
  
  Print("\n=== Audio Frequency Analyzer ===\n");
  Print("Target: Danziger Straße 123.m4a\n");
  Print("Looking for hidden messages...\n\n");
  
  // Generate simulated audio with hidden pattern
  for (i = 0; i < SAMPLE_RATE; i++) {
    F64 t = i / ToF64(SAMPLE_RATE);
    
    // Base audio
    samples[i].left = Sin(2 * π * 440 * t) * 0.5;  // A4 note
    
    // Hidden ultrasonic carrier at 19kHz
    samples[i].left += Sin(2 * π * 19000 * t) * 0.1;
    
    // Encode "GAIA" in phase modulation
    if (i % 1000 < 250) {
      samples[i].left += Sin(2 * π * 5000 * t + 'G' * π / 128) * 0.05;
    } else if (i % 1000 < 500) {
      samples[i].left += Sin(2 * π * 5000 * t + 'A' * π / 128) * 0.05;
    } else if (i % 1000 < 750) {
      samples[i].left += Sin(2 * π * 5000 * t + 'I' * π / 128) * 0.05;
    } else {
      samples[i].left += Sin(2 * π * 5000 * t + 'A' * π / 128) * 0.05;
    }
    
    samples[i].right = samples[i].left;
    samples[i].timestamp = i;
  }
  
  // Analyze spectrum
  AnalyzeSpectrum(samples, SAMPLE_RATE, bins);
  
  // Detect patterns
  DetectHiddenPatterns(bins, FREQ_BINS);
  
  // Extract messages
  ExtractMessagesFromFrequencies(bins, FREQ_BINS);
  
  // Visualize
  VisualizeSpectrum(bins, FREQ_BINS);
  
  Print("\n=== Analysis Complete ===\n");
  Print("To analyze actual file, need audio decoder implementation.\n");
}

// Main entry point
U0 AudioFrequencyAnalyzer() {
  Print("Initializing Audio Frequency Analyzer...\n");
  Print("Searching for hidden messages in audio glitches...\n\n");
  
  SimulateAudioAnalysis();
}

AudioFrequencyAnalyzer;