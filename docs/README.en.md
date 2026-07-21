# Price Monitor

> A macOS menu-bar utility for comparing storefront prices and stock while tracking WOYAO API balance and recent usage.

[简体中文](../README.md) · **English** · [日本語](README.ja.md) · [한국어](README.ko.md)

![price-monitor-macos project visual](assets/price-monitor-macos-hero.png)

| Release | Platform | Architecture | License |
| --- | --- | --- | --- |
| v1.4 | macOS 14+ | Apple Silicon | MIT License |

[Download latest release](../../releases/latest) · [Quick start](#quick-start) · [Star this project](../../stargazers)

## What it does

Price Monitor keeps two frequently checked sources in one local app: prices and stock from selected storefronts, plus WOYAO API balance and usage. It starts with macOS, shows the current WOYAO balance in the menu bar, and opens a fuller window only when comparison is needed.

It never places orders or payments. Selecting a product simply opens that product page in the default browser.

## Highlights

- Groups comparable products and sorts each group from the lowest price upward.
- Checks storefronts every minute and speaks when a newly available item appears.
- Shows the current WOYAO balance directly in the menu bar.
- Refreshes WOYAO usage hourly and speaks the balance, used quota, and today’s cost.
- Lists the latest ten calls with model, cost, tokens, and timestamp.
- Tolerates numeric, string, and null values returned by the usage service; a log-list issue does not block balance data.

## Quick start

1. Download `PriceMonitor-v1.4-macOS-arm64.zip` from [Releases](../../releases/latest), unzip it, and move the app to Applications.
2. Open the app once. To start it automatically after login, install the user-level template in `LaunchAgent.plist`.
3. Open **WOYAO Usage**, paste your API key, and choose **Save to Documents and Read**.
4. The key is stored only at `Documents/价格监控/woyao-api-key.txt`; storefront monitoring needs no login.

## How it works

Public storefront APIs feed the local price comparison, new-stock speech alerts, and browser product links. WOYAO usage APIs feed the menu-bar balance, hourly spoken summary, and latest-call list. The hero image is a concept illustration, not a screenshot or real account data.

## Privacy and boundaries

- Storefront data is read from public storefront APIs.
- You manually enter the WOYAO API key. The app writes it only to a local Documents file with current-user-only permissions.
- Keys are not written to this repository, ordinary logs, or browser data.
- Release assets contain no keys, balances, usage logs, cookies, crash reports, or login data.

The Documents key file is plaintext. Do not sync it to a public drive or commit it to Git.

## Build

macOS, Xcode Command Line Tools, and Swift 6 are required.

```zsh
./build_app.sh
```

The script creates `价格监控.app`. Local build output is ignored by Git; use Release assets for distribution.

## License

This project is released under the [MIT License](../LICENSE). You may use, copy, modify, commercially use, and redistribute it, provided that the copyright and license notice are retained.

## Downloads and verification

Each release includes an arm64 macOS archive and a `.sha256` file. Verify the downloaded archive with:

```zsh
shasum -a 256 PriceMonitor-v1.4-macOS-arm64.zip
```

Compare the result with the SHA-256 file in the same release.

## Known limitations

- Only Apple Silicon (arm64) is built and verified.
- The app is locally signed but not Apple-notarized; on first launch you may need to Control-click it in Finder and choose Open.
