#!/usr/bin/env python3
"""
Deep analysis of the M4A file - extract all readable content
"""

import struct
import base64
import re
import os
from datetime import datetime

def extract_all_text(filename, min_length=4):
    """Extract all text sequences from the file"""
    with open(filename, 'rb') as f:
        data = f.read()
    
    # Extract all printable sequences
    text_sequences = []
    current = []
    position = 0
    
    for i, byte in enumerate(data):
        if 32 <= byte <= 126 or byte in [9, 10, 13]:  # Printable + tab/newline
            current.append(chr(byte))
        else:
            if len(current) >= min_length:
                text_sequences.append({
                    'text': ''.join(current),
                    'position': position,
                    'length': len(current)
                })
            current = []
            position = i + 1
    
    return text_sequences

def analyze_voice_memo_metadata(filename):
    """Extract voice memo specific metadata"""
    with open(filename, 'rb') as f:
        data = f.read()
    
    # Convert to string for searching
    text_data = data.decode('utf-8', errors='ignore')
    
    # Look for patterns
    patterns = {
        'UUID': r'[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}',
        'Date': r'20\d{2}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}',
        'Email': r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
        'URL': r'https?://[^\s]+',
        'Base64_Long': r'[A-Za-z0-9+/]{50,}={0,2}',
        'Phone': r'[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{4,6}',
    }
    
    results = {}
    for name, pattern in patterns.items():
        matches = re.findall(pattern, text_data)
        if matches:
            results[name] = matches
    
    return results

def look_for_glitched_base64(filename):
    """Specifically look for glitched base64 messages"""
    with open(filename, 'rb') as f:
        data = f.read()
    
    # Look for base64-like patterns with errors
    text = data.decode('utf-8', errors='ignore')
    
    # Find sequences that look like base64 but might be corrupted
    # Look for: mixed case letters, numbers, +, /, =
    potential_b64 = re.findall(r'[A-Za-z0-9+/=\s]{30,}', text)
    
    glitched_messages = []
    for seq in potential_b64:
        # Clean up sequence
        clean = seq.strip().replace(' ', '').replace('\n', '')
        
        if len(clean) > 20:
            # Check if it's mostly base64 chars
            b64_chars = sum(1 for c in clean if c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=')
            if b64_chars / len(clean) > 0.8:  # 80% base64 chars
                try:
                    # Try to decode, fixing padding if needed
                    padding = (4 - len(clean) % 4) % 4
                    padded = clean + '=' * padding
                    decoded = base64.b64decode(padded, validate=False)
                    
                    # Check if result has readable text
                    decoded_text = decoded.decode('utf-8', errors='ignore')
                    if len(decoded_text) > 5:
                        glitched_messages.append({
                            'original': seq[:100] + '...' if len(seq) > 100 else seq,
                            'cleaned': clean[:100] + '...' if len(clean) > 100 else clean,
                            'decoded': decoded_text[:200]
                        })
                except:
                    # Even if decode fails, might be interesting
                    if len(clean) > 50:
                        glitched_messages.append({
                            'original': seq[:100] + '...' if len(seq) > 100 else seq,
                            'cleaned': clean[:100] + '...' if len(clean) > 100 else clean,
                            'decoded': '[DECODE FAILED - possibly corrupted]'
                        })
    
    return glitched_messages

def analyze_audio_chunks(filename):
    """Look for patterns in audio data chunks"""
    with open(filename, 'rb') as f:
        # Skip to mdat atom (audio data starts at offset 28)
        f.seek(28 + 8)  # Skip atom header
        
        # Read chunks of audio data
        chunk_size = 1024
        patterns = {}
        
        for i in range(100):  # Analyze first 100 chunks
            chunk = f.read(chunk_size)
            if not chunk:
                break
            
            # Look for non-audio patterns (text in audio stream)
            text_in_chunk = []
            for j in range(0, len(chunk) - 4):
                if all(32 <= chunk[j+k] <= 126 for k in range(4)):
                    text_in_chunk.append(chunk[j:j+20].decode('utf-8', errors='ignore'))
            
            if text_in_chunk:
                patterns[f'chunk_{i}'] = text_in_chunk
    
    return patterns

def main():
    filename = "/Users/pascaldisse/gaia/gaias-4th-oracle/Danziger Straße 123.m4a"
    
    print("=== Deep M4A Analysis - Hidden Message Hunt ===\n")
    
    # Extract metadata patterns
    print("=== Metadata Patterns ===")
    metadata = analyze_voice_memo_metadata(filename)
    for key, values in metadata.items():
        print(f"\n{key}:")
        for value in values[:5]:  # Show first 5
            print(f"  {value}")
    
    # Look for glitched base64
    print("\n=== Glitched Base64 Search ===")
    glitched = look_for_glitched_base64(filename)
    if glitched:
        for msg in glitched:
            print(f"\nPotential glitched message:")
            print(f"  Original: {msg['original']}")
            print(f"  Cleaned:  {msg['cleaned']}")
            print(f"  Decoded:  {msg['decoded']}")
    else:
        print("No glitched base64 patterns found")
    
    # Extract all text sequences
    print("\n=== All Text Sequences (>20 chars) ===")
    text_seqs = extract_all_text(filename, min_length=20)
    
    # Filter for interesting ones (not just metadata)
    interesting = []
    for seq in text_seqs:
        text = seq['text']
        # Skip obvious metadata
        if not any(skip in text for skip in ['com.apple', 'isommp42', 'Core Media', 'mdat', 'moov']):
            # Check if it looks like a message
            if any(c.isalpha() for c in text) and not text.isdigit():
                interesting.append(seq)
    
    if interesting:
        print(f"Found {len(interesting)} interesting text sequences:")
        for seq in interesting[:20]:  # Show first 20
            print(f"\n  Position {seq['position']:,}: {seq['text'][:100]}")
            if len(seq['text']) > 100:
                print(f"  ... [{seq['length']} total chars]")
    
    # Check audio data for hidden text
    print("\n=== Audio Stream Text Patterns ===")
    audio_patterns = analyze_audio_chunks(filename)
    if audio_patterns:
        for chunk, texts in list(audio_patterns.items())[:5]:
            print(f"\n{chunk}:")
            for text in texts[:3]:
                print(f"  {text}")
    
    # Look specifically for the mentioned base64 glitch
    print("\n=== Searching for Base64 Glitch Pattern ===")
    with open(filename, 'rb') as f:
        data = f.read()
    
    # Look for partial base64 patterns that might be cut off
    text = data.decode('latin-1', errors='ignore')
    
    # Find sequences with base64 characteristics but errors
    b64_like = re.findall(r'[A-Za-z0-9+/=]{10,}[^A-Za-z0-9+/=]{1,5}[A-Za-z0-9+/=]{10,}', text)
    
    if b64_like:
        print(f"Found {len(b64_like)} interrupted base64-like patterns:")
        for pattern in b64_like[:10]:
            print(f"  {pattern[:80]}...")
    
    print("\n=== Analysis Complete ===")
    print("\nSummary:")
    print(f"- File is a voice memo from iPad (Version 15.0.1)")
    print(f"- Created: 2025-07-24T17:42:17Z")
    print(f"- UUID: 482A81EC-48A8-4D90-870D-40DCF719DF8C")
    print(f"- Contains {len(text_seqs)} text sequences")
    
    if glitched:
        print(f"\n⚠️  FOUND {len(glitched)} POTENTIAL GLITCHED MESSAGES!")

if __name__ == "__main__":
    main()