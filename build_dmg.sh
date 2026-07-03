#!/bin/bash

# ==============================================================================
#  MockAppleDevice 自动化打包脚本 - CYBER CORE BUILDER V1.1
# ==============================================================================

# 颜色常量定义 (Cyberpunk 配色)
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 错误拦截
set -e

echo -e "${PURPLE}"
cat << 'EOF'
    __  ___           __    ___                __      ____             _
   /  |/  /___  _____/ /__ /   |  ____  ____  / /__   / __ \___ _   __  (_)________
  / /|_/ / __ \/ ___/ //_// /| | / __ \/ __ \/ / _ \ / / / / _ \ | / / / / ___/ _ \
 / /  / / /_/ / /__/ ,<  / ___ |/ /_/ / /_/ / /  __// /_/ /  __/ |/ / / / /__/  __/
/_/  /_/\____/\___/_/|_|/_/  |_/ .___/ .___/_/\___//_____/\___/|___/ /_/\___/\___/
                              /_/   /_/
EOF
echo -e "${CYAN}=========================== AUTOMATED DMG BUILD SHIELD ===========================${NC}\n"

# 1. 变量准备
PROJECT_NAME="MockAppleDevice"
APP_NAME="MockAppleDevice"
DMG_NAME="${APP_NAME}.dmg"
WORKSPACE_DIR="$(pwd)"
BUILD_DIR="${WORKSPACE_DIR}/build"
DIST_DIR="${WORKSPACE_DIR}/dist"
IPA_DIR="${WORKSPACE_DIR}/ipa"
TARGET_APP="${BUILD_DIR}/Release/${APP_NAME}.app"
TARGET_DMG="${IPA_DIR}/${DMG_NAME}"

# 2. 环境清理
echo -e "${YELLOW}[1/5] 🌪 正在清理旧的编译和打包残余...${NC}"
rm -rf "${BUILD_DIR}"
rm -rf "${DIST_DIR}"
rm -f "${TARGET_DMG}"
mkdir -p "${IPA_DIR}"
echo -e "${GREEN}✓ 清理完毕。${NC}\n"

# 3. 编译 App 产物 (Release 配置，仅 arm64 架构)
echo -e "${YELLOW}[2/5] 🛠 正在通过 xcodebuild 编译 Release 产物 (SYMROOT)...${NC}"
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
           -scheme "${PROJECT_NAME}" \
           -configuration Release \
           -destination 'platform=macOS' \
           SYMROOT="${BUILD_DIR}" \
           ONLY_ACTIVE_ARCH=NO \
           ARCHS="arm64" \
           clean build > /dev/null

if [ -d "${TARGET_APP}" ]; then
    echo -e "${GREEN}✓ 编译成功！生成目标应用: ${TARGET_APP}${NC}\n"
else
    echo -e "${RED}✗ 编译失败，未能在预期目录找到 .app 产物！${NC}"
    exit 1
fi

# 4. 组装 DMG 分发临时舱 (dist)
echo -e "${YELLOW}[3/5] 📦 正在准备打包分发舱镜像 (链接 Applications)...${NC}"
mkdir -p "${DIST_DIR}"
cp -R "${TARGET_APP}" "${DIST_DIR}/"

# 在临时舱内创建指向系统 Applications 的软链接，以便用户拖拽安装
ln -s /Applications "${DIST_DIR}/Applications"
echo -e "${GREEN}✓ 镜像目录组装完毕。${NC}\n"

# 5. 打包只读压缩 DMG
echo -e "${YELLOW}[4/5] 💿 正在调用 hdiutil 生成只读压缩磁盘映像 (UDZO)...${NC}"
hdiutil create -volname "${APP_NAME}" \
               -srcfolder "${DIST_DIR}" \
               -ov \
               -format UDZO \
               "${TARGET_DMG}" > /dev/null

echo -e "${GREEN}✓ DMG 生成成功: ${TARGET_DMG}${NC}\n"

# 6. 后置清理
echo -e "${YELLOW}[5/5] 🧹 正在回收临时打包空间...${NC}"
rm -rf "${DIST_DIR}"
rm -rf "${BUILD_DIR}"
echo -e "${GREEN}✓ 临时空间已全部安全回收。${NC}\n"

# 7. 终极炫酷宣告
echo -e "${GREEN}================================================================================${NC}"
echo -e "${GREEN}⚡️ 自动化打包圆满成功！极客只读磁盘镜像 [${DMG_NAME}] 已就绪。${NC}"
echo -e "${CYAN}📂 文件路径: ${TARGET_DMG}${NC}"
echo -e "${GREEN}================================================================================${NC}"
