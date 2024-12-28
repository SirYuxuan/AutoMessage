#!/bin/bash

# 设置变量
APP_NAME="AutoMessage"
DMG_NAME="${APP_NAME}.dmg"
VOLUME_NAME="${APP_NAME}"
SOURCE_APP="./build/Release/${APP_NAME}.app"
DMG_PATH="./build/${DMG_NAME}"
TMP_DMG_PATH="./build/${APP_NAME}_tmp.dmg"

# 确保build目录存在
mkdir -p ./build

# 创建临时DMG
hdiutil create -size 100m -fs HFS+ -volname "${VOLUME_NAME}" "${TMP_DMG_PATH}"

# 挂载DMG
hdiutil attach "${TMP_DMG_PATH}"

# 复制应用到DMG
cp -R "${SOURCE_APP}" "/Volumes/${VOLUME_NAME}/"

# 创建Applications软链接
ln -s /Applications "/Volumes/${VOLUME_NAME}/Applications"

# 等待文件系统同步
sync

# 卸载DMG
hdiutil detach "/Volumes/${VOLUME_NAME}"

# 转换DMG为压缩格式
hdiutil convert "${TMP_DMG_PATH}" -format UDZO -o "${DMG_PATH}"

# 清理临时文件
rm "${TMP_DMG_PATH}"

echo "DMG created at: ${DMG_PATH}" 