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

def get_fallback_rect(category):
    if category == "iphone":
        return 0.045, 0.018, 0.910, 0.964
    elif category == "ipad":
        return 0.038, 0.028, 0.924, 0.944
    elif category == "macbook":
        return 0.082, 0.032, 0.836, 0.548
    elif category == "appleWatch":
        return 0.088, 0.205, 0.824, 0.590
    return 0.1, 0.1, 0.8, 0.8

def detect_screen_rect(image_path, category, orientation):
    """
    通过扫描图片透明区域（Alpha=0）的外包围盒，自适应计算高精度屏幕比例。
    针对 iPhone 特殊处理：
      - 竖屏（portrait）：Y 轴（上下）由于灵动岛干扰，统一使用标准硬编码比例 (y: 0.018, height: 0.964)；X 轴（左右）使用自适应扫描，以完美贴合超窄边框。
      - 横屏（landscape）：X 轴（左右，此时为头尾）由于灵动岛在左侧干扰，统一使用标准硬编码比例 (x: 0.018, width: 0.964)；Y 轴（上下，此时为左右两侧）使用自适应扫描，以完美贴合侧边。
    其他品类（iPad/Watch/Mac）正常使用全方向自动扫描。
    """
    try:
        from PIL import Image
        img = Image.open(image_path).convert("RGBA")
        width, height = img.size
        cx, cy = width // 2, height // 2
        
        # 搜寻透明的起点
        if img.getpixel((cx, cy))[3] != 0:
            found = False
            for offset in range(min(width, height) // 2):
                for dx, dy in [(-offset, 0), (offset, 0), (0, -offset), (0, offset)]:
                    tx, ty = cx + dx, cy + dy
                    if 0 <= tx < width and 0 <= ty < height and img.getpixel((tx, ty))[3] == 0:
                        cx, cy = tx, ty
                        found = True
                        break
                if found: break
            if not found:
                return get_fallback_rect(category)
        
        margin_x = 0.006
        margin_y = 0.006
        
        # iPhone 混合定位逻辑
        if category == "iphone":
            if orientation == "portrait":
                # 向左扫描
                left = cx
                while left > 0 and img.getpixel((left - 1, cy))[3] == 0:
                    left -= 1
                # 向右扫描
                right = cx
                while right < width - 1 and img.getpixel((right + 1, cy))[3] == 0:
                    right += 1
                
                ry = 0.018
                rh = 0.964
                rx = max(0.0, left / width - margin_x)
                rw = min(1.0, (right - left + 1) / width + 2 * margin_x)
                return rx, ry, rw, rh
            else:
                # 向上扫描
                top = cy
                while top > 0 and img.getpixel((cx, top - 1))[3] == 0:
                    top -= 1
                # 向下扫描
                bottom = cy
                while bottom < height - 1 and img.getpixel((cx, bottom + 1))[3] == 0:
                    bottom += 1
                
                rx = 0.018
                rw = 0.964
                ry = max(0.0, top / height - margin_y)
                rh = min(1.0, (bottom - top + 1) / height + 2 * margin_y)
                return rx, ry, rw, rh
        
        # 非 iPhone 设备继续进行完整的上下左右扫描
        # 向左扫描
        left = cx
        while left > 0 and img.getpixel((left - 1, cy))[3] == 0:
            left -= 1
        # 向右扫描
        right = cx
        while right < width - 1 and img.getpixel((right + 1, cy))[3] == 0:
            right += 1
            
        # 向上/向下扫描使用偏离中央 25% 宽度的 scan_x 轴线，以避开屏幕中央刘海 (Notch) / 摄像头等实色块的阻挡
        scan_x = cx - width // 4
        if img.getpixel((scan_x, cy))[3] != 0:
            found_scan_x = False
            for dx in range(-width // 8, width // 8):
                tx = scan_x + dx
                if 0 <= tx < width and img.getpixel((tx, cy))[3] == 0:
                    scan_x = tx
                    found_scan_x = True
                    break
            if not found_scan_x:
                scan_x = cx
                
        # 向上扫描
        top = cy
        while top > 0 and img.getpixel((scan_x, top - 1))[3] == 0:
            top -= 1
        # 向下扫描
        bottom = cy
        while bottom < height - 1 and img.getpixel((scan_x, bottom + 1))[3] == 0:
            bottom += 1
            
        # 0.1% 微小重叠边距，为 iPad/MacBook 边框提供更加宽敞和精致的“呼吸感”
        margin_x_non_iphone = 0.001
        margin_y_non_iphone = 0.001
        
        rx = max(0.0, left / width - margin_x_non_iphone)
        ry = max(0.0, top / height - margin_y_non_iphone)
        rw = min(1.0, (right - left + 1) / width + 2 * margin_x_non_iphone)
        rh = min(1.0, (bottom - top + 1) / height + 2 * margin_y_non_iphone)
        
        return rx, ry, rw, rh
    except Exception as e:
        print(f"Auto detect failed for {image_path}: {e}")
        return get_fallback_rect(category)

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
            
            # 获取当前图片贴合的相对比例，传入方向以使用横竖屏自适应机制
            x, y, w, h = detect_screen_rect(abs_path, category, orientation)
            
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
