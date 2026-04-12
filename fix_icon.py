from PIL import Image
import os

def optimize_icon(src, dst, size=(192, 192)):
    try:
        with Image.open(src) as img:
            # Convert to RGBA and resize with high quality
            img = img.convert("RGBA")
            img = img.resize(size, Image.Resampling.LANCZOS)
            
            # Create a simple transparent background if needed
            # (The source should already be transparent, but this ensures compatibility)
            
            # Save without any extra metadata or ICC profile
            # This is crucial for AAPT2 compatibility
            img.save(dst, "PNG", optimize=True)
            print(f"Successfully optimized {src} -> {dst}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    src_path = "assets/shark_logo.png"
    dst_path = "Proximity-Shark-WearOS/app/src/main/res/drawable/icon.png"
    optimize_icon(src_path, dst_path)
