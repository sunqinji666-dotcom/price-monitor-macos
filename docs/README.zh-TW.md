# 價格監控

> 在 macOS 選單列中查看指定商店的價格、庫存，以及 WOYAO API 餘額與近期用量的本機工具。

[简体中文](../README.md) · **繁體中文** · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## 功能

- 將可比較商品分組，並依價格由低至高排序。
- 每分鐘檢查商店；新商品或補貨時以 macOS 語音通知。
- 直接在選單列顯示目前 WOYAO 餘額。
- 每小時讀取用量並播報餘額、已用額度和當日花費。
- 顯示最近 10 筆呼叫的模型、費用、Token 與時間。

## 快速開始

1. 從 [Releases](../../releases/latest) 下載 `PriceMonitor-v1.4-macOS-arm64.zip`，解壓縮後移到「應用程式」。
2. 開啟應用程式；需要登入後自動啟動時，安裝 `LaunchAgent.plist` 的使用者範本。
3. 在 **WOYAO 用量** 頁貼上 API Key，選擇「儲存到文件並讀取」。

## 隱私

商品資料只讀取公開商店 API。WOYAO Key 只保存在 `Documents/价格监控/woyao-api-key.txt`，不會寫入 Git、一般日誌或瀏覽器資料。請勿把這個明文檔同步到公開雲端。

## 建置與授權

需要 macOS、Xcode Command Line Tools 與 Swift 6。執行 `./build_app.sh` 產生 `价格监控.app`。

本專案採用 [MIT License](../LICENSE)。作者與聯絡方式：Jacksun（孫秦吉）· [qinji@jack-sun.com](mailto:qinji@jack-sun.com)。
