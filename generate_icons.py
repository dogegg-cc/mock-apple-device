import os
import sys
import json

def install_pillow_if_needed():
    try:
        from PIL import Image
    except ImportError:
        print("Pillow not found, installing via pip...")
        import subprocess
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "pillow"])
            print("Pillow successfully installed!")
        except Exception as e:
            print(f"Failed to install Pillow: {e}")
            sys.exit(1)

# Ensure Pillow is installed
install_pillow_if_needed()

from PIL import Image, ImageDraw, ImageFilter

def create_smooth_mask(size, radius):
    """
    Creates a high-quality antialiased rounded rectangle mask using supersampling.
    """
    width, height = size
    scale = 4
    # Create mask at 4x resolution
    large_size = (width * scale, height * scale)
    mask = Image.new("L", large_size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, large_size[0], large_size[1]), radius * scale, fill=255)
    # Resize down with Lanczos to get smooth antialiased edges
    return mask.resize((width, height), Image.Resampling.LANCZOS)

def generate_macos_icon(logo_path):
    """
    Generates a master 1024x1024 macOS-style app icon:
    - Active area: 824x824 centered
    - Corner radius: 181.25px
    - Shadow: Soft blur (radius 20px), offset y +16px, opacity 25%
    - Subtle border: 1px black outline at 10% opacity
    """
    print(f"Reading source logo from: {logo_path}")
    logo = Image.open(logo_path).convert("RGBA")
    
    canvas_size = 1024
    active_size = 824
    radius = 181.25
    
    # 1. Resize logo to the active area size
    logo_resized = logo.resize((active_size, active_size), Image.Resampling.LANCZOS)
    
    # 2. Crop logo to macOS rounded rectangle shape
    mask = create_smooth_mask((active_size, active_size), radius)
    cropped_logo = Image.new("RGBA", (active_size, active_size), (0, 0, 0, 0))
    cropped_logo.paste(logo_resized, (0, 0), mask)
    
    # 3. Add a subtle dark border around the active logo boundary to blend it nicely
    draw = ImageDraw.Draw(cropped_logo)
    # 1px border at 10% opacity black
    draw.rounded_rectangle(
        (0, 0, active_size - 1, active_size - 1), 
        radius, 
        outline=(0, 0, 0, 25), 
        width=1
    )
    
    # 4. Create the shadow
    shadow_offset_y = 16
    shadow_blur_radius = 20
    shadow_base = Image.new("RGBA", (active_size, active_size), (0, 0, 0, 0))
    # 25% opacity black shadow
    shadow_color = Image.new("RGBA", (active_size, active_size), (0, 0, 0, int(255 * 0.25)))
    shadow_base.paste(shadow_color, (0, 0), mask)
    
    # Paste shadow to a temporary canvas to apply blur
    shadow_canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    shadow_x = (canvas_size - active_size) // 2
    shadow_y = (canvas_size - active_size) // 2 + shadow_offset_y
    shadow_canvas.paste(shadow_base, (shadow_x, shadow_y))
    
    # Apply Gaussian blur
    shadow_blurred = shadow_canvas.filter(ImageFilter.GaussianBlur(shadow_blur_radius))
    
    # 5. Assemble final macOS icon
    final_icon = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    final_icon.paste(shadow_blurred, (0, 0), shadow_blurred)
    
    logo_x = (canvas_size - active_size) // 2
    logo_y = (canvas_size - active_size) // 2
    final_icon.paste(cropped_logo, (logo_x, logo_y), cropped_logo)
    
    print("Successfully generated master macOS-style 1024x1024 icon.")
    return final_icon

def export_all_icons(master_icon, appiconset_dir):
    """
    Exports the master icon to all required sizes in the AppIcon.appiconset directory
    and writes/updates Contents.json.
    """
    # Specs as defined in Contents.json
    specs = [
        {"size": 16,  "scale": "1x", "filename": "icon_16x16.png"},
        {"size": 16,  "scale": "2x", "filename": "icon_16x16@2x.png"}, # 32x32
        {"size": 32,  "scale": "1x", "filename": "icon_32x32.png"},
        {"size": 32,  "scale": "2x", "filename": "icon_32x32@2x.png"}, # 64x64
        {"size": 128, "scale": "1x", "filename": "icon_128x128.png"},
        {"size": 128, "scale": "2x", "filename": "icon_128x128@2x.png"}, # 256x256
        {"size": 256, "scale": "1x", "filename": "icon_256x256.png"},
        {"size": 256, "scale": "2x", "filename": "icon_256x256@2x.png"}, # 512x512
        {"size": 512, "scale": "1x", "filename": "icon_512x512.png"},
        {"size": 512, "scale": "2x", "filename": "icon_512x512@2x.png"}  # 1024x1024
    ]
    
    print(f"Exporting icons to: {appiconset_dir}")
    os.makedirs(appiconset_dir, exist_ok=True)
    
    # Generate and save each size
    for spec in specs:
        target_pixel_size = spec["size"] * int(spec["scale"].replace("x", ""))
        dest_path = os.path.join(appiconset_dir, spec["filename"])
        
        # Resize from master icon using high quality Lanczos resampling
        resized = master_icon.resize((target_pixel_size, target_pixel_size), Image.Resampling.LANCZOS)
        resized.save(dest_path, "PNG")
        print(f"  Saved {spec['filename']} ({target_pixel_size}x{target_pixel_size} px)")
        
    # Write Contents.json
    contents = {
        "images": [
            {
                "idiom": "mac",
                "scale": spec["scale"],
                "size": f"{spec['size']}x{spec['size']}",
                "filename": spec["filename"]
            } for spec in specs
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    contents_path = os.path.join(appiconset_dir, "Contents.json")
    with open(contents_path, "w", encoding="utf-8") as f:
        json.dump(contents, f, indent=2)
    print(f"Successfully updated Contents.json at: {contents_path}")

if __name__ == "__main__":
    project_root = "/Users/jiao/Desktop/Project/MockAppleDevice"
    logo_path = os.path.join(project_root, "logo.png")
    appiconset_dir = os.path.join(project_root, "MockAppleDevice", "Assets.xcassets", "AppIcon.appiconset")
    
    if not os.path.exists(logo_path):
        print(f"Error: logo.png not found at {logo_path}")
        sys.exit(1)
        
    master_icon = generate_macos_icon(logo_path)
    export_all_icons(master_icon, appiconset_dir)
    print("\nIcon generation completed successfully!")
