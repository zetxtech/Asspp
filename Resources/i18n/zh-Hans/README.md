# 爱啪思道

**多账号、多地区 App Store 管理神器。**

Asspp 专为需要管理**多个 Apple ID** 和**跨区下载**的用户打造。你可以在不同国家的 App Store 之间无缝切换，随意浏览和下载应用，完全无需退出系统账号。

[English 🇺🇸](../../../README.md)

![Preview](../../../Resources/Screenshots/Apptisan_Asspp.png)

## ℹ️ 关于本分支

本分支修复了登录与下载，旁加载后也能正常使用：

- **登录修复**：恢复 Apple 账号签名认证，登录和下载稳定可靠。
- **旁加载友好**：通过 LiveContainer、TrollStore、AltStore 等工具安装后认证不再损坏，不再出现「本地认证签名失败」之类的错误。

**致谢**：感谢原作者 [Lakr](https://github.com/Lakr233) 及 [Asspp](https://github.com/Lakr233/Asspp) 的全部贡献者；同时感谢 [Majd Alfhaily](https://github.com/majd) 与上游 [ipatool](https://github.com/majd/ipatool) 提供的 SAP 签名认证实现。

## ✨ 核心亮点

- **🌍 全球商店漫游**：想看美区、日区还是国区的应用？一键切换，即刻浏览。告别繁琐的换区流程。
- **👥 多账号无缝切换**：支持添加无限个 Apple ID。Asspp 会根据你浏览的商店区域，自动匹配对应的账号进行下载。
- **📦 IPA 提取与管理**：直接从 Apple 服务器下载官方正版 IPA 文件，方便备份、存档或通过巨魔（TrollStore）安装。
- **⏪ 历史版本回退**：轻松查询并下载 App 的旧版本，不再受制于强制更新。
- **📱 双端原生体验**：同时支持 **iOS** 和 **macOS**，提供流畅的原生操作体验。

## 📥 安装指南

### iOS

#### 方案一：自动构建与签名（推荐）

Fork 本仓库并配置 GitHub Actions，使用你自己的开发者证书自动构建。这样你可以获得一个永久有效的 **OTA 安装链接**，且能自动跟随上游更新，无需电脑即可在手机上安装。

👉 **[详细配置指南](../../../Resources/Document/FORK_AUTOBUILD_GUIDE.md)** (英文)

#### 方案二：手动安装

1.  前往 [Releases](https://github.com/Lakr233/Asspp/releases) 下载最新的 `.ipa` 文件。
2.  使用你习惯的签名工具（如 SideStore, AltStore, TrollStore, 巨魔等）进行签名安装。

### macOS

1.  前往 [Releases](https://github.com/Lakr233/Asspp/releases) 下载最新的 `.zip` 文件。
2.  解压并将 `Asspp.app` 拖入“应用程序”文件夹。
3.  **首次运行与信任应用（推荐步骤）**：
    1.  尝试双击打开应用；若出现“无法打开，因为无法确认开发者”或类似提示：
        - 在 Finder 中定位到 `Asspp.app`，按住 **Control** 键并点击（或右键点击）应用图标，选择 **打开**，在弹窗中再次点击 **打开**。此操作会为该应用建立信任记录，通常只需执行一次。
    2.  如果 Control+点击无效或仍受阻：
        - 打开 **系统设置** -> **隐私与安全**（或“系统偏好设置 -> 安全性与隐私”旧版 macOS），在“通用/安全性”区域的底部查找被阻止的应用并点击 **仍要打开** 或 **允许**，可能需要输入管理员密码。
    3.  建议从本仓库 Releases 下载并核验发布信息，确保来源可信后再按上述方法信任并打开应用。

    > 说明：以上步骤是 macOS Gatekeeper 的标准处理方式，旨在保护系统安全。按照推荐流程操作可以最小化风险并确保应用能正常运行。

## 🛠 系统要求

- **iOS**: iOS 17.0 或更高版本。
- **macOS**: macOS 15.0 或更高版本。
- **Apple ID**: 需要登录以访问 App Store API。

## 🚨 特别声明

Asspp 底层使用了与 `ipatool` 相同的通信协议。根据社区反馈与推测（未经官方证实），该协议此前经历过数次失效，其原因可能包括：
1. 工具被大规模滥用触发了风控机制；
2. 苹果修复了 iCloud 的相关安全漏洞并随之更改了协议；
3. 苹果调整了前置网关，对流量分配与请求特征提出了更严格的要求。

鉴于苹果对相关接口的管控日益严格，**若未来该协议再次失效，本项目可能将无法提供后续修复。**

**⚠️ 重要安全提醒：**
1. **妥善保管 GUID：** 请务必将您的设备 GUID 视同核心密码妥善保存，切勿泄露给他人。
2. **切勿使用主力 Apple ID：** 强烈建议您使用备用账号登录本工具。若因使用本工具导致账号被苹果封禁，可能会引发设备被“激活锁”永久锁定的风险（尽管目前尚未出现此类极端案例，但我们无法提供任何安全保证）。

## ⚠️ 免责声明

本项目仅供学习和研究使用，与 Apple Inc. 无关。使用本软件产生的任何后果由用户自行承担。

## 🥰 鸣谢

- [ipatool](https://github.com/majd/ipatool)
- [ipatool-ios](https://github.com/dlevi309/ipatool-ios)
- [localhost.direct](https://get.localhost.direct/)

_`ipatool-ios` 和 `localhost.direct` 已在当前项目中不再使用。_

## 📄 许可证

MIT License. 详见 [LICENSE](../../../LICENSE)。

---

Copyright © 2025 Lakr Aream. All Rights Reserved.
