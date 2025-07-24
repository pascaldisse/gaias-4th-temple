#!/usr/bin/env python3
"""
Direct M4A file analysis - looks for hidden messages in the file structure
"""

import struct
import base64
import re
import os

def read_m4a_atoms(filename):
    """Read M4A/MP4 atom structure"""
    atoms = []
    
    with open(filename, 'rb') as f:
        file_size = os.path.getsize(filename)
        pos = 0
        
        while pos < file_size:
            f.seek(pos)
            
            # Read atom header (size + type)
            header = f.read(8)
            if len(header) < 8:
                break
                
            atom_size = struct.unpack('>I', header[:4])[0]
            atom_type = header[4:8].decode('ascii', errors='ignore')
            
            # Read atom data
            if atom_size == 1:  # 64-bit size
                size_data = f.read(8)
                atom_size = struct.unpack('>Q', size_data)[0]
                data_start = pos + 16
            else:
                data_start = pos + 8
            
            if atom_size == 0:  # Extends to end of file
                atom_size = file_size - pos
            
            # Read some atom data
            f.seek(data_start)
            data_preview = f.read(min(1024, atom_size - 8))
            
            atoms.append({
                'type': atom_type,
                'size': atom_size,
                'position': pos,
                'data_preview': data_preview
            })
            
            pos += atom_size
            
    return atoms

def find_base64_patterns(data):
    """Look for base64 encoded strings in binary data"""
    # Convert to string, ignoring errors
    text = data.decode('utf-8', errors='ignore')
    
    # Look for base64 patterns (continuous alphanumeric + /+ with = padding)
    base64_pattern = r'[A-Za-z0-9+/]{20,}={0,2}'
    matches = re.findall(base64_pattern, text)
    
    results = []
    for match in matches:
        try:
            # Try to decode
            decoded = base64.b64decode(match)
            # Check if result is printable
            if all(32 <= b <= 126 or b in [9, 10, 13] for b in decoded[:100]):
                results.append({
                    'encoded': match[:100] + '...' if len(match) > 100 else match,
                    'decoded': decoded[:100].decode('utf-8', errors='ignore')
                })
        except:
            pass
            
    return results

def analyze_metadata(atoms):
    """Analyze metadata atoms for hidden content"""
    metadata_atoms = ['meta', 'udta', 'ilst', 'moov', 'uuid']
    suspicious = []
    
    for atom in atoms:
        if atom['type'] in metadata_atoms:
            # Look for non-standard patterns
            data = atom['data_preview']
            
            # Check for hidden text
            text = data.decode('utf-8', errors='ignore')
            words = re.findall(r'[A-Za-z]{4,}', text)
            
            if words:
                suspicious.append({
                    'atom': atom['type'],
                    'position': atom['position'],
                    'words': words[:10]  # First 10 words
                })
                
    return suspicious

def extract_binary_patterns(filename):
    """Look for steganographic patterns in the binary"""
    with open(filename, 'rb') as f:
        data = f.read(1024 * 1024)  # First 1MB
        
    # Look for repeating patterns
    patterns = {}
    window_size = 16
    
    for i in range(0, len(data) - window_size, window_size):
        pattern = data[i:i+window_size]
        pattern_hex = pattern.hex()
        
        if pattern_hex in patterns:
            patterns[pattern_hex] += 1
        else:
            patterns[pattern_hex] = 1
    
    # Find unusual patterns (appear multiple times but not too many)
    suspicious_patterns = []
    for pattern, count in patterns.items():
        if 3 <= count <= 20:  # Appears 3-20 times
            suspicious_patterns.append({
                'pattern': pattern,
                'count': count,
                'ascii': bytes.fromhex(pattern).decode('utf-8', errors='ignore')
            })
            
    return suspicious_patterns

def main():
    filename = "/Users/pascaldisse/gaia/gaias-4th-oracle/Danziger Straße 123.m4a"
    
    print("=== M4A Direct Analysis ===")
    print(f"File: {filename}")
    print(f"Size: {os.path.getsize(filename):,} bytes\n")
    
    # Read atom structure
    print("Reading M4A atom structure...")
    atoms = read_m4a_atoms(filename)
    
    print(f"\nFound {len(atoms)} atoms:")
    for atom in atoms[:20]:  # Show first 20
        print(f"  {atom['type']:4s} - Size: {atom['size']:10,} bytes at position {atom['position']}")
    
    # Look for base64 in atoms
    print("\n=== Searching for Base64 Messages ===")
    for atom in atoms:
        b64_results = find_base64_patterns(atom['data_preview'])
        if b64_results:
            print(f"\nFound in {atom['type']} atom:")
            for result in b64_results:
                print(f"  Encoded: {result['encoded']}")
                print(f"  Decoded: {result['decoded']}")
    
    # Analyze metadata
    print("\n=== Metadata Analysis ===")
    suspicious_meta = analyze_metadata(atoms)
    if suspicious_meta:
        for item in suspicious_meta:
            print(f"\nAtom {item['atom']} at {item['position']}:")
            print(f"  Words found: {', '.join(item['words'])}")
    else:
        print("No suspicious metadata found")
    
    # Look for binary patterns
    print("\n=== Binary Pattern Analysis ===")
    patterns = extract_binary_patterns(filename)
    if patterns:
        print(f"Found {len(patterns)} suspicious repeating patterns:")
        for p in patterns[:5]:  # Show top 5
            print(f"  Pattern: {p['pattern'][:32]}... (appears {p['count']} times)")
            if p['ascii'].strip():
                print(f"    ASCII: {p['ascii']}")
    
    # Check for glitched sections
    print("\n=== Glitch Detection ===")
    with open(filename, 'rb') as f:
        data = f.read()
        
    # Look for null byte sequences (common in glitches)
    null_sequences = []
    i = 0
    while i < len(data):
        if data[i] == 0:
            start = i
            while i < len(data) and data[i] == 0:
                i += 1
            length = i - start
            if length > 100:  # Significant null sequence
                null_sequences.append((start, length))
        else:
            i += 1
    
    if null_sequences:
        print(f"Found {len(null_sequences)} null byte sequences:")
        for pos, length in null_sequences[:5]:
            print(f"  Position {pos:,}: {length:,} null bytes")
    
    # Look for text fragments
    print("\n=== Text Fragment Search ===")
    with open(filename, 'rb') as f:
        data = f.read()
        
    # Extract printable ASCII sequences
    text_fragments = []
    current = []
    for byte in data:
        if 32 <= byte <= 126:  # Printable ASCII
            current.append(chr(byte))
        else:
            if len(current) > 10:  # Significant text
                fragment = ''.join(current)
                if not fragment.isdigit():  # Skip pure numbers
                    text_fragments.append(fragment)
            current = []
    
    if text_fragments:
        print(f"Found {len(text_fragments)} text fragments:")
        for fragment in text_fragments[:10]:
            print(f"  {fragment[:60]}...")
    
    print("\n=== Analysis Complete ===")

if __name__ == "__main__":
    main()