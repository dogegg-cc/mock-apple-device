import os
import sys
import json
import urllib.request
import ssl

ssl._create_default_https_context = ssl._create_unverified_context

def install_pillow_if_needed():
    try:
        from PIL import Image
    except ImportError:
        print("Pillow not found, installing via pip...")
        import subprocess
        subprocess.check_call([sys.executable, "-m", "pip", "install", "pillow"])

install_pillow_if_needed()
from PIL import Image

def detect_screen_rect(image_path, asset_name):
    """
    通过扫描图像中非透明的黑色屏幕区域，自动推算屏幕的 CGRect。
    为避免 MacBook 下半部分的键盘干扰，对不同设备采用不同的扫描策略。
    """
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    
    left, top, right, bottom = width, height, 0, 0
    found = False
    
    # 限制扫描范围
    y_limit = height
    if "macbook" in asset_name:
        # MacBook 只扫描上半部分 (72%以内)，完美避开底座键盘
        y_limit = int(height * 0.72)
        
    for x in range(width):
        for y in range(y_limit):
            r, g, b, a = img.getpixel((x, y))
            # 屏幕通常是纯黑或接近纯黑，且不透明
            # 阈值调高一点，a > 200，rgb < 35
            if a > 200 and r < 35 and g < 35 and b < 35:
                if x < left: left = x
                if y < top: top = y
                if x > right: right = x
                if y > bottom: bottom = y
                found = True
                
    if not found:
        print(f"[{asset_name}] Black screen not found. Falling back to default.")
        return 0.1, 0.1, 0.8, 0.8
        
    x_ratio = left / width
    y_ratio = top / height
    w_ratio = (right - left + 1) / width
    h_ratio = (bottom - top + 1) / height
    
    return x_ratio, y_ratio, w_ratio, h_ratio

def download_and_import(url, asset_name, project_dir):
    print(f"\nDownloading {asset_name} from {url}...")
    headers = {"User-Agent": "Mozilla/5.0"}
    req = urllib.request.Request(url, headers=headers)
    
    temp_path = f"temp_{asset_name}.png"
    try:
        with urllib.request.urlopen(req) as response, open(temp_path, "wb") as out_file:
            out_file.write(response.read())
    except Exception as e:
        print(f"Failed to download {asset_name}: {e}")
        return None
        
    # 检测屏幕坐标
    x_ratio, y_ratio, w_ratio, h_ratio = detect_screen_rect(temp_path, asset_name)
    print(f"Detected screen rect for {asset_name}:")
    print(f"  x: {x_ratio:.4f}, y: {y_ratio:.4f}, w: {w_ratio:.4f}, h: {h_ratio:.4f}")
    
    # 导入 Assets.xcassets
    assets_dir = os.path.join(project_dir, "MockAppleDevice", "Assets.xcassets")
    imageset_dir = os.path.join(assets_dir, f"{asset_name}.imageset")
    os.makedirs(imageset_dir, exist_ok=True)
    
    dest_path = os.path.join(imageset_dir, f"{asset_name}.png")
    if os.path.exists(dest_path):
        os.remove(dest_path)
    os.rename(temp_path, dest_path)
    
    # 生成 Contents.json
    contents = {
        "images": [
            {
                "filename": f"{asset_name}.png",
                "idiom": "universal",
                "scale": "1x"
            },
            {
                "idiom": "universal",
                "scale": "2x"
            },
            {
                "idiom": "universal",
                "scale": "3x"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    with open(os.path.join(imageset_dir, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
        
    print(f"Successfully imported {asset_name} into Assets.")
    return {
        "x": x_ratio,
        "y": y_ratio,
        "width": w_ratio,
        "height": h_ratio
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python process_assets.py <project_dir>")
        sys.exit(1)
        
    project_dir = sys.argv[1]
    
    devices = {
        "iphone_15_pro": "https://raw.githubusercontent.com/jonnyjackson26/device-frames-media/main/device-frames-output/Apple%20iPhone/15%20Pro%20Max/Natural%20Titanium/frame.png",
        "ipad_pro": "https://raw.githubusercontent.com/jonnyjackson26/device-frames-media/main/device-frames-output/Apple%20iPad/iPad%20Pro%2011%20M4%20%26%20M5/Portrait%20-%20Space%20Black/frame.png",
        "macbook_pro": "https://raw.githubusercontent.com/ephread/PommePlate/main/MacBook/PNG/MacBook%20Pro%2016-inch%20-%20Space%20Gray.png",
        "apple_watch": "https://raw.githubusercontent.com/ephread/PommePlate/main/Apple%20Watch/PNG/Apple%20Watch%2044mm.png"
    }
    
    results = {}
    for name, url in devices.items():
        coords = download_and_import(url, name, project_dir)
        if coords:
            results[name] = coords
            
    print("\n--- DETECTED COORDINATES SUMMARY ---")
    print("Copy these values into your DeviceConfig.swift file:\n")
    print(json.dumps(results, indent=4))
