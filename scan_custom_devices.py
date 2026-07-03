import os
import sys
import json
import re
import shutil

def install_pillow_if_needed():
    try:
        from PIL import Image
    except ImportError:
        print("Pillow not found, installing via pip...")
        import subprocess
        subprocess.check_call([sys.executable, "-m", "pip", "install", "pillow"])

def detect_screen_rect(image_path, category):
    """
    提供比物理屏幕尺寸稍微大 1%~2% 的“安全重叠比例” (Overlap Safety Margin)。
    因为设备外边框图盖在截图顶层，截图稍大可以被金属边框完美压住，
    从而达到 100% 严丝合缝的覆盖效果，绝不露底、露缝。
    """
    if category == "iphone":
        # 往外扩展 1% 以压实边缘，解决露灰边、白缝问题
        return 0.045, 0.018, 0.910, 0.964
    elif category == "ipad":
        return 0.038, 0.028, 0.924, 0.944
    elif category == "macbook":
        return 0.082, 0.032, 0.836, 0.548
    elif category == "appleWatch":
        return 0.088, 0.205, 0.824, 0.590
    return 0.1, 0.1, 0.8, 0.8

def clean_asset_name(name):
    clean = name.lower()
    clean = re.sub(r'[^a-z0-9]+', '_', clean)
    clean = clean.strip('_')
    return clean

def main(project_dir):
    device_dir = os.path.join(project_dir, "Device")
    assets_dir = os.path.join(project_dir, "MockAppleDevice", "Assets.xcassets")
    
    if not os.path.exists(device_dir):
        print(f"Error: Custom Device folder not found at {device_dir}")
        sys.exit(1)
        
    print(f"Scanning custom mockups under: {device_dir}")
    
    device_db = {}
    
    for root, dirs, files in os.walk(device_dir):
        for file in files:
            if not file.endswith(".png") or file.startswith("."):
                continue
                
            abs_path = os.path.join(root, file)
            rel_path = os.path.relpath(abs_path, device_dir)
            
            # 解析得到: 品类, 型号, 颜色/表带, 方向
            category, model, color, orientation = parse_metadata(rel_path)
            
            # 获取当前图片贴合的相对比例
            x, y, w, h = detect_screen_rect(abs_path, category)
            
            # 统一 asset 的名称
            asset_name = clean_asset_name(f"{model}_{color}_{orientation}")
            
            # 导入 Assets.xcassets
            imageset_dir = os.path.join(assets_dir, f"{asset_name}.imageset")
            os.makedirs(imageset_dir, exist_ok=True)
            
            dest_path = os.path.join(imageset_dir, f"{asset_name}.png")
            if os.path.exists(dest_path):
                os.remove(dest_path)
            
            # 直接拷贝原始设备图片，因为原始图片本身已经是圆角透明屏幕抠空
            shutil.copy(abs_path, dest_path)
            
            # 写入 xcassets 的 Contents.json (Single Scale)
            contents = {
                "images": [
                    {
                        "filename": f"{asset_name}.png",
                        "idiom": "universal"
                    }
                ],
                "info": {
                    "author": "xcode",
                    "version": 1
                }
            }
            with open(os.path.join(imageset_dir, "Contents.json"), "w") as f:
                json.dump(contents, f, indent=2)
                
            # 记录到配置数据库中
            if category not in device_db:
                device_db[category] = {}
            if model not in device_db[category]:
                device_db[category][model] = {}
            if color not in device_db[category][model]:
                device_db[category][model][color] = {}
                
            device_db[category][model][color][orientation] = {
                "imageName": asset_name,
                "screenRect": {
                    "x": x,
                    "y": y,
                    "width": w,
                    "height": h
                }
            }
            print(f"Processed: [{category.upper()}] {model} ({color}) [{orientation}] -> rect: {x:.3f},{y:.3f},{w:.3f},{h:.3f}")
            
    # 输出 JSON 配置文件
    output_json_path = os.path.join(project_dir, "MockAppleDevice", "device_models.json")
    with open(output_json_path, "w") as f:
        json.dump(device_db, f, indent=2, ensure_ascii=False)
        
    print(f"\n--- SUCCESS ---")
    print(f"Imported all mockups and wrote device config JSON to: {output_json_path}")

def parse_metadata(rel_path):
    parts = rel_path.split(os.sep)
    filename = os.path.splitext(parts[-1])[0]
    
    category = "iphone"
    lower_path = rel_path.lower()
    if "ipad" in lower_path:
        category = "ipad"
    elif "macbook" in lower_path:
        category = "macbook"
    elif "watch" in lower_path:
        category = "appleWatch"
        
    orientation = "portrait"
    if "landscape" in filename.lower():
        orientation = "landscape"
    elif "portrait" in filename.lower():
        orientation = "portrait"
    else:
        if category == "macbook":
            orientation = "landscape"
        else:
            orientation = "portrait"
            
    model = ""
    color = ""
    
    if category in ["iphone", "ipad"]:
        clean_name = filename
        for sfx in [" - Portrait", " - Landscape", "-Portrait", "-Landscape"]:
            clean_name = re.sub(sfx, "", clean_name, flags=re.IGNORECASE)
            
        if " - " in clean_name:
            subparts = clean_name.split(" - ")
            model = subparts[0].strip()
            color = subparts[1].strip()
        else:
            model = clean_name.strip()
            color = "Default"
            
    elif category == "macbook":
        clean_name = filename
        known_colors = ["Space Black", "Space Gray", "Silver", "Gold", "Midnight", "Starlight"]
        matched_color = None
        for kc in known_colors:
            if clean_name.endswith(kc):
                matched_color = kc
                break
        if matched_color:
            model = clean_name[:-len(matched_color)].strip()
            color = matched_color
        else:
            words = clean_name.split()
            if len(words) > 1:
                model = " ".join(words[:-1])
                color = words[-1]
            else:
                model = clean_name
                color = "Default"
                
    elif category == "appleWatch":
        clean_name = filename
        if "AW Ultra 3" in clean_name:
            model = "Apple Watch Ultra 3"
        elif "AW Series 11" in clean_name:
            model = "Apple Watch Series 11"
        else:
            model = parts[0].replace("-", " ")
            
        if " - " in clean_name:
            color = clean_name.split(" - ")[1].strip()
        else:
            color = clean_name
            
    return category, model, color, orientation

if __name__ == "__main__":
    p_dir = "/Users/jiao/Desktop/Project/MockAppleDevice"
    if len(sys.argv) > 1:
        p_dir = sys.argv[1]
    main(p_dir)
