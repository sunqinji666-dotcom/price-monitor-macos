# 价格监控

> 一个常驻 macOS 菜单栏的小工具：对比指定店铺商品价格与库存，并显示 WOYAO API 余额和最近调用。

**简体中文** · [繁體中文](docs/README.zh-TW.md) · [English](docs/README.en.md) · [日本語](docs/README.ja.md) · [한국어](docs/README.ko.md) · [Español](docs/README.es.md) · [Français](docs/README.fr.md) · [Deutsch](docs/README.de.md) · [Português](docs/README.pt-BR.md) · [Русский](docs/README.ru.md) · [العربية](docs/README.ar.md) · [हिन्दी](docs/README.hi.md) · [Bahasa Indonesia](docs/README.id.md)

作者与联系：**Jacksun（孙秦吉）** · [qinji@jack-sun.com](mailto:qinji@jack-sun.com)

![价格监控概念主视觉：深色 macOS 风格仪表盘、价格标签、余额卡片和提醒铃铛。](docs/assets/price-monitor-hero.png)

| 当前版本 | 支持系统 | 架构 | 许可证 |
| --- | --- | --- | --- |
| v1.4 | macOS 14+ | Apple 芯片 | MIT License |

[下载最新版本](../../releases/latest) · [快速开始](#一分钟上手) · [收藏项目](../../stargazers)

## 这是什么

价格监控把原本需要反复打开网页检查的两类信息放到一个本地应用里：指定店铺的商品价格/库存，以及 WOYAO 的 API 余额和调用记录。应用开机启动，菜单栏只显示 WOYAO 当前余额；需要比较商品时再打开完整窗口。

这是本地工具，不代替下单或付款。点击商品后只会交给默认浏览器打开该商品购买页。

## 为什么有用

- 三家店铺的同类商品自动分组，组内按价格从低到高排列。
- 每分钟检查商品；有新的在售商品或补货时使用 macOS 语音播报。
- 菜单栏直接显示 WOYAO 当前余额，不用打开网页。
- WOYAO 每小时播报余额、已用额度和今日消费。
- 最近 10 条调用列出模型、费用、Token 与时间，方便核对实际消耗。
- 兼容服务端数值、字符串和空值字段；调用日志异常不会挡住余额显示。

## 一分钟上手

1. 在 [Releases](../../releases/latest) 下载 `PriceMonitor-v1.4-macOS-arm64.zip`，解压后拖入“应用程序”。
2. 首次打开应用。若需要登录后自动启动，可按项目内 `LaunchAgent.plist` 安装用户级启动项。
3. 打开“WOYAO 用量”，粘贴 API Key 并点击“保存到文档并读取”。
4. Key 仅保存到 `文档/价格监控/woyao-api-key.txt`；商品监控无需登录。

## 工作方式

```text
公开店铺商品接口 ─┐
                   ├─ 本地价格监控 ── 商品分组 / 新货语音播报 / 浏览器购买页
WOYAO 用量接口 ────┘                 └─ 菜单栏余额 / 每小时用量播报 / 最近 10 条调用
```

上图为功能流程，页面主视觉为概念示意，不包含真实账号、余额或调用数据。

## 功能与边界

### 商品价格

默认监控以下公开店铺：

- `https://pay.ldxp.cn/shop/2GO2Z6GD`
- `https://pay.ldxp.cn/shop/K1PKHQ1F`
- `https://pay.ldxp.cn/shop/mlxggpt`

新上架的商品会显示；下架商品会在下一次刷新后消失。缺货商品保留为“缺货”状态，重新有货也会被视为新货播报。

### WOYAO 用量

需要用户自行提供有效 API Key。应用读取余额、额度、今日/累计消费与最近 10 条调用；它不会帮你下单、充值、调用模型或修改远端账号设置。

## 隐私

- 商品数据来自公开店铺接口。
- WOYAO Key 由用户手动输入，保存到本机文档目录，权限设置为仅当前用户可读写。
- Key 不写入项目文件、Git、普通日志或浏览器数据。
- Release 不包含你的 Key、余额、调用日志、Cookie、崩溃记录或登录数据。

文档目录中的 Key 是明文文件；请不要将该文件同步到公共网盘或提交到 Git。

## 项目结构

```text
Sources/PriceMonitor/  SwiftUI 应用与接口逻辑
Assets/                应用图标源文件
docs/                  12 种语言 README 与发布视觉
build_app.sh           生成 macOS .app 的脚本
LaunchAgent.plist      登录启动项模板
```

## 开发与构建

需要 macOS、Xcode Command Line Tools 与 Swift 6。

```zsh
./build_app.sh
```

构建结果为 `价格监控.app`。本地开发产物被 `.gitignore` 排除；正式发布包由 Release 提供。

## 许可证

本项目采用 [MIT License](LICENSE)。任何人都可以自由使用、复制、修改、商业使用和再次发布，但需保留版权与许可声明。

## 下载与校验

发布资产包含 macOS arm64 压缩包及对应 `.sha256` 文件。下载后可在终端核验：

```zsh
shasum -a 256 PriceMonitor-v1.4-macOS-arm64.zip
```

请将输出与 Release 中的 SHA-256 文件比对。

## 已知限制

- 当前只构建并验证 Apple Silicon（arm64）版本。
- 应用为本地自签名构建，未进行 Apple 公证；首次打开可能需要在 Finder 中按住 Control 点击并选择“打开”。
