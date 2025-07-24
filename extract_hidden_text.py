#!/usr/bin/env python3
"""
Extract the hidden JSON text from the M4A file
"""

import json

def extract_json_text(filename):
    """Extract the JSON text found in the file"""
    with open(filename, 'rb') as f:
        data = f.read()
    
    # Look for the JSON starting with tsrp
    start_marker = b'tsrp'
    start_pos = data.find(start_marker)
    
    if start_pos == -1:
        print("Marker not found")
        return None
    
    # Skip the 'tsrp' marker and find the JSON
    json_start = start_pos + 4
    
    # Find the end of the JSON (look for closing braces)
    brace_count = 0
    in_string = False
    escape_next = False
    
    for i in range(json_start, min(json_start + 100000, len(data))):
        byte = data[i]
        char = chr(byte) if 32 <= byte <= 126 else ''
        
        if escape_next:
            escape_next = False
            continue
            
        if char == '\\':
            escape_next = True
            continue
            
        if char == '"' and not escape_next:
            in_string = not in_string
            continue
            
        if not in_string:
            if char == '{':
                brace_count += 1
            elif char == '}':
                brace_count -= 1
                if brace_count == 0:
                    # Found the end
                    json_data = data[json_start:i+1].decode('utf-8', errors='ignore')
                    return json_data
    
    # If we didn't find proper end, extract what we can
    json_data = data[json_start:json_start+50000].decode('utf-8', errors='ignore')
    return json_data

def parse_and_display_json(json_str):
    """Parse and display the JSON content"""
    try:
        data = json.loads(json_str)
        
        # Extract the attributed string
        if 'attributedString' in data:
            attr_str = data['attributedString']
            
            # Reconstruct the text from runs
            if 'runs' in attr_str:
                runs = attr_str['runs']
                
                # Build the complete text
                text_parts = []
                i = 0
                while i < len(runs):
                    if isinstance(runs[i], str):
                        text_parts.append(runs[i])
                    i += 1
                
                full_text = ''.join(text_parts)
                
                print("=== HIDDEN MESSAGE FOUND ===\n")
                print(full_text)
                
                # Save to file
                with open('hidden_message.txt', 'w', encoding='utf-8') as f:
                    f.write(full_text)
                print("\n\nFull message saved to: hidden_message.txt")
                
                # Also extract any formatting info
                if 'attributes' in attr_str:
                    print("\n=== Formatting Attributes ===")
                    for attr in attr_str['attributes'][:10]:  # Show first 10
                        print(f"  {attr}")
                        
        return data
        
    except json.JSONDecodeError as e:
        print(f"JSON decode error: {e}")
        # Try to extract readable parts
        print("\n=== Raw text extraction ===")
        
        # Look for text between quotes
        import re
        texts = re.findall(r'"([^"]+)"', json_str)
        
        # Filter and join meaningful texts
        meaningful = []
        for text in texts:
            if len(text) > 3 and not text.isdigit() and text not in ['runs', 'attributes', 'string']:
                meaningful.append(text)
        
        if meaningful:
            reconstructed = ' '.join(meaningful)
            print(reconstructed)
            
            with open('hidden_message_raw.txt', 'w', encoding='utf-8') as f:
                f.write(reconstructed)
            print("\n\nRaw message saved to: hidden_message_raw.txt")

def main():
    filename = "/Users/pascaldisse/gaia/gaias-4th-oracle/Danziger Straße 123.m4a"
    
    print("=== Extracting Hidden JSON Message ===\n")
    
    json_text = extract_json_text(filename)
    
    if json_text:
        print(f"Found JSON text: {len(json_text)} characters\n")
        
        # Save raw JSON
        with open('hidden_json_raw.json', 'w', encoding='utf-8') as f:
            f.write(json_text)
        print("Raw JSON saved to: hidden_json_raw.json\n")
        
        # Parse and display
        parse_and_display_json(json_text)
    else:
        print("No JSON text found")

if __name__ == "__main__":
    main()