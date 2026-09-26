import SwiftUI

enum MonitorPreference {
    static let timedMonitoringEnabled = "timedMonitoringEnabled"
    static let notificationsEnabled = "notificationsEnabled"
    static let speechEnabled = "speechEnabled"
    static let speakProductUpdates = "speakProductUpdates"
    static let speakProductPrice = "speakProductPrice"
    static let speakBalanceUpdates = "speakBalanceUpdates"
    static let speechVoiceIdentifier = "speechVoiceIdentifier"
    static let productRefreshMinutes = "productRefreshMinutes"
    static let rightAPIRefreshMinutes = "rightAPIRefreshMinutes"
    static let productSpeechScope = "productSpeechScope"
    static let productSpeechCategoriesKey = "productSpeechCategories"

    static func bool(_ key: String, default defaultValue: Bool = true) -> Bool {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: key) == nil ? defaultValue : defaults.bool(forKey: key)
    }

    static func storedProductSpeechCategories() -> Set<String> {
        let raw = UserDefaults.standard.string(forKey: productSpeechCategoriesKey) ?? ""
        return Set(raw.split(separator: ",").map(String.init))
    }

    static func setStoredProductSpeechCategories(_ categories: Set<String>) {
        UserDefaults.standard.set(categories.sorted().joined(separator: ","), forKey: productSpeechCategoriesKey)
    }

    /// 语音播报范围：默认全部；仅在“仅以下分类”模式下按选中分类过滤。
    static func productSpeechAllows(_ group: String) -> Bool {
        guard UserDefaults.standard.string(forKey: productSpeechScope) == "selected" else { return true }
        return storedProductSpeechCategories().contains(group)
    }
}

struct AppSettingsView: View {
    @EnvironmentObject private var priceMonitor: PriceMonitor
    @EnvironmentObject private var rightAPIMonitor: RightAPIUsageMonitor

    @AppStorage(MonitorPreference.timedMonitoringEnabled) private var timedMonitoringEnabled = true
    @AppStorage(MonitorPreference.notificationsEnabled) private var notificationsEnabled = true
    @AppStorage(MonitorPreference.speechEnabled) private var speechEnabled = false
    @AppStorage(MonitorPreference.speakProductUpdates) private var speakProductUpdates = true
    @AppStorage(MonitorPreference.speakProductPrice) private var speakProductPrice = true
    @AppStorage(MonitorPreference.speakBalanceUpdates) private var speakBalanceUpdates = true
    @AppStorage(MonitorPreference.speechVoiceIdentifier) private var speechVoiceIdentifier = ""
    @AppStorage(MonitorPreference.productSpeechScope) private var productSpeechScope = "all"
    @AppStorage(MonitorPreference.productSpeechCategoriesKey) private var productSpeechCategoriesRaw = ""

    var body: some View {
        Form {
            Section("定时监控") {
                Toggle("开启自动定时监控", isOn: $timedMonitoringEnabled)
                    .onChange(of: timedMonitoringEnabled) { _, _ in applyMonitoringSettings() }
                LabeledContent("商品与库存") {
                    minuteEditor(value: $priceMonitor.autoRefreshMinutes)
                        .onChange(of: priceMonitor.autoRefreshMinutes) { _, _ in priceMonitor.configureAutoRefresh() }
                }
                LabeledContent("RightAPI 余额") {
                    minuteEditor(value: $rightAPIMonitor.monitorIntervalMinutes)
                        .onChange(of: rightAPIMonitor.monitorIntervalMinutes) { _, _ in rightAPIMonitor.configureMonitoring() }
                }
                Text("每项都可输入 1–1440 分钟，也可用加减按钮微调。关闭后所有自动刷新停止，手动刷新仍可使用。")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("提醒方式") {
                Toggle("显示 macOS 系统通知", isOn: $notificationsEnabled)
                Toggle("开启语音播报", isOn: $speechEnabled)
                Toggle("播报商品上架与补货", isOn: $speakProductUpdates)
                    .disabled(!speechEnabled)
                Toggle("商品播报包含价格", isOn: $speakProductPrice)
                    .disabled(!speechEnabled || !speakProductUpdates)
                Toggle("播报余额变化", isOn: $speakBalanceUpdates)
                    .disabled(!speechEnabled)
                LabeledContent("语音音色") {
                    HStack {
                        Picker("语音音色", selection: $speechVoiceIdentifier) {
                            Text("系统默认 · 婷婷").tag("")
                            Section("推荐本地音色") {
                                ForEach(SpeechAnnouncer.recommendedVoiceChoices) { voice in
                                    Text(voice.displayName).tag(voice.id)
                                }
                            }
                            Section("其他本机中文音色") {
                                ForEach(SpeechAnnouncer.otherVoiceChoices) { voice in
                                    Text(voice.displayName).tag(voice.id)
                                }
                            }
                        }
                        .labelsHidden()
                        .frame(width: 220)
                        Button("试听") { SpeechAnnouncer.shared.preview() }
                    }
                }
                .disabled(!speechEnabled)
                Text("推荐音色均已安装在这台 Mac，本地合成语音，不上传播报文字。")
                    .font(.caption).foregroundStyle(.secondary)
                Text("系统通知和语音可以独立使用；语音关闭时仍可保留静默通知。")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("语音播报范围") {
                Picker("播报范围", selection: $productSpeechScope) {
                    Text("全部商品").tag("all")
                    Text("仅以下分类").tag("selected")
                }
                .disabled(!speechEnabled || !speakProductUpdates)

                if productSpeechScope == "selected" {
                    HStack {
                        Button("全选") {
                            selectAllSpeechCategories(true)
                        }
                        Button("清空") {
                            selectAllSpeechCategories(false)
                        }
                        Spacer()
                    }
                    .controlSize(.small)
                    .disabled(!speechEnabled || !speakProductUpdates)

                    ForEach(availableSpeechCategories, id: \.self) { category in
                        Toggle(category, isOn: speechCategoryBinding(for: category))
                            .disabled(!speechEnabled || !speakProductUpdates)
                    }
                }
                Text("系统通知仍会提示全部新上架/补货商品；语音只播报这里选中的分类。")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("本地数据") {
                LabeledContent("RightAPI Key", value: "文档/价格监控/rightapi-api-key.txt")
            Text("RightAPI Key 只保存在本机，文件权限仅当前用户可读写。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 8)
    }

    private func applyMonitoringSettings() {
        priceMonitor.configureAutoRefresh()
        rightAPIMonitor.configureMonitoring()
    }

    private func minuteEditor(value: Binding<Int>) -> some View {
        HStack(spacing: 8) {
            TextField("分钟", value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 72)
            Text("分钟").foregroundStyle(.secondary)
            Stepper("", value: value, in: 1...1440)
                .labelsHidden()
        }
        .disabled(!timedMonitoringEnabled)
    }

    private var availableSpeechCategories: [String] {
        var categories = Set(Product.speechCategories)
        categories.formUnion(priceMonitor.products.map(\.comparisonGroup))
        return categories.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private func speechCategoryBinding(for category: String) -> Binding<Bool> {
        Binding(
            get: {
                MonitorPreference.storedProductSpeechCategories().contains(category)
            },
            set: { isOn in
                var categories = MonitorPreference.storedProductSpeechCategories()
                if isOn {
                    categories.insert(category)
                } else {
                    categories.remove(category)
                }
                MonitorPreference.setStoredProductSpeechCategories(categories)
                productSpeechCategoriesRaw = categories.sorted().joined(separator: ",")
            }
        )
    }

    private func selectAllSpeechCategories(_ isOn: Bool) {
        let categories: Set<String> = isOn ? Set(availableSpeechCategories) : []
        MonitorPreference.setStoredProductSpeechCategories(categories)
        productSpeechCategoriesRaw = categories.sorted().joined(separator: ",")
    }
}
