#!/usr/bin/env python3
"""
Script para criar portraits placeholder para os pilotos.
Cria imagens coloridas simples de 256x256 pixels.
Requer: pip install pillow
"""

# Se PIL não estiver disponível, criar manualmente PNGs mínimos
# Este script deve ser executado com: python3 create_placeholders.py

import struct
import zlib

def create_minimal_png(width, height, r, g, b, filename):
    """
    Cria um PNG mínimo de cor sólida sem usar PIL.
    """
    def png_pack(png_tag, data):
        chunk_head = png_tag
        return (struct.pack("!I", len(data)) +
                chunk_head +
                data +
                struct.pack("!I", 0xFFFFFFFF & zlib.crc32(chunk_head + data)))

    # PNG Header
    png_header = b'\x89PNG\r\n\x1a\n'

    # IHDR chunk
    ihdr = struct.pack("!2I5B", width, height, 8, 2, 0, 0, 0)

    # IDAT chunk - raw pixel data
    raw_data = b""
    for y in range(height):
        raw_data += b'\x00'  # Filter type 0 (None)
        for x in range(width):
            raw_data += struct.pack("!3B", r, g, b)

    compressed_data = zlib.compress(raw_data, 9)

    # IEND chunk
    iend = b''

    # Combine all chunks
    png_data = (png_header +
                png_pack(b'IHDR', ihdr) +
                png_pack(b'IDAT', compressed_data) +
                png_pack(b'IEND', iend))

    with open(filename, 'wb') as f:
        f.write(png_data)
    print(f"Created: {filename}")

# Pilot colors based on their archetype
pilots = [
    # ("filename", r, g, b, "name")
    ("tank_commander_pilot.png", 128, 128, 200, "Tank Commander"),  # Blue - Tank
    ("speed_demon_pilot.png", 255, 255, 100, "Speed Demon"),  # Yellow - Speed
    ("engineer_pilot.png", 150, 150, 150, "Engineer"),  # Gray - Support
    ("dual_wielder_pilot.png", 200, 100, 100, "Dual Wielder"),  # Red - DPS
    ("combo_master_pilot.png", 255, 150, 50, "Combo Master"),  # Orange - DPS
    ("scavenger_pilot.png", 150, 200, 100, "Scavenger"),  # Green - Support
    ("berserker_pilot.png", 200, 50, 200, "Berserker"),  # Magenta - DPS
]

# Create 256x256 placeholder images
for filename, r, g, b, name in pilots:
    create_minimal_png(256, 256, r, g, b, filename)
    print(f"  -> {name}")

print("\nDone! Created 7 placeholder portraits.")
print("These can be replaced with actual artwork later.")
