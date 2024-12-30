
# AutoMessage

![Version](https://img.shields.io/github/v/release/SirYuxuan/AutoMessage)
![License](https://img.shields.io/github/license/SirYuxuan/AutoMessage)
![Platform](https://img.shields.io/badge/platform-macOS-blue)

AutoMessage 是一款 macOS 应用，自动识别并填写验证码，提升您的工作效率。

## 功能简介
- 自动识别短信验证码并快速填写
- 菜单栏一键管理
- 支持多应用验证码识别
- 安全可靠，完全本地运行

## 下载与安装
### 通过 Homebrew Cask 安装
```bash
brew tap SirYuxuan/tap
brew install --cask automessage
```

### 手动下载
您也可以直接[下载最新版本](https://github.com/SirYuxuan/AutoMessage/releases)并手动安装。  

1. 下载 `AutoMessage.app.zip`  
2. 解压后将 `AutoMessage.app` 拖入 `/Applications` 文件夹  

## 使用说明
1. 安装后，首次运行需要授予必要的系统权限（例如读取短信权限）。  
2. AutoMessage 将在菜单栏显示，点击菜单栏图标即可管理应用。  
3. 验证码短信到达后，AutoMessage 会自动识别并在输入框中填充验证码。  

## 卸载方法
```bash
brew uninstall automessage
```

## 兼容性
- macOS Ventura 及以上版本

## 常见问题
### 1. AutoMessage 无法自动填写验证码？
- 请确认已授予“辅助功能”权限。  
- 在“系统设置 -> 隐私与安全性 -> 辅助功能”中添加 AutoMessage。  

### 2. 验证码识别错误？
- 确认短信格式符合标准验证码格式。  
- 部分短信可能需要手动输入。  

## 贡献
欢迎贡献代码或提交问题反馈。  
1. Fork 本仓库  
2. 提交 PR 或 issue  

## 许可证
本项目遵循 [MIT 许可证](LICENSE)。


