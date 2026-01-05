//
//  FluxWidget.swift
//  FluxWidget
//
//  显示已用流量的小组件
//

import WidgetKit
import SwiftUI

// MARK: - 数据模型

struct FluxData: Codable {
    let totalFlow: Int64      // 总流量 (GB)
    let usedFlow: Int64       // 已用流量 (bytes)
    let expTime: String?      // 到期时间
    let serverURL: String?    // 服务器地址
    let lastUpdate: Date      // 最后更新时间
    
    var usagePercentage: Double {
        guard totalFlow > 0 else { return 0 }
        let totalBytes = Double(totalFlow) * 1024 * 1024 * 1024
        return min(Double(usedFlow) / totalBytes, 1.0)
    }
    
    var formattedUsedFlow: String {
        let bytes = Double(usedFlow)
        if bytes < 1024 {
            return String(format: "%.0f B", bytes)
        } else if bytes < 1024 * 1024 {
            return String(format: "%.2f KB", bytes / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.2f MB", bytes / (1024 * 1024))
        } else if bytes < 1024 * 1024 * 1024 * 1024 {
            return String(format: "%.2f GB", bytes / (1024 * 1024 * 1024))
        } else {
            return String(format: "%.2f TB", bytes / (1024 * 1024 * 1024 * 1024))
        }
    }
    
    var formattedTotalFlow: String {
        if totalFlow <= 0 {
            return "Unlimited"
        }
        if totalFlow >= 1024 {
            return String(format: "%.1f TB", Double(totalFlow) / 1024)
        }
        return "\(totalFlow) GB"
    }
    
    var isUnlimited: Bool {
        return totalFlow <= 0
    }
    
    var isExpired: Bool {
        guard let expTime = expTime, !expTime.isEmpty else { return false }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: expTime) {
            return date < Date()
        }
        
        // 尝试其他格式
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = dateFormatter.date(from: expTime) {
            return date < Date()
        }
        
        return false
    }
    
    var formattedExpTime: String {
        guard let expTime = expTime, !expTime.isEmpty else { return "无限期" }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var date: Date?
        date = formatter.date(from: expTime)
        
        if date == nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            date = dateFormatter.date(from: expTime)
        }
        
        if let date = date {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM-dd"
            return "至 " + displayFormatter.string(from: date)
        }
        
        return expTime
    }
}

// MARK: - Timeline Provider

struct FluxProvider: TimelineProvider {
    static let appGroupID = "group.nz.owo.Flux"
    
    func placeholder(in context: Context) -> FluxEntry {
        FluxEntry(date: Date(), data: nil, isPlaceholder: true)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FluxEntry) -> Void) {
        let data = loadFluxData()
        let entry = FluxEntry(date: Date(), data: data, isPlaceholder: false)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FluxEntry>) -> Void) {
        // 先尝试从网络刷新数据
        fetchFluxDataFromServer { fetchedData in
            let data = fetchedData ?? loadFluxData()
            let entry = FluxEntry(date: Date(), data: data, isPlaceholder: false)
            
            // 每 15 分钟刷新一次
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private func loadFluxData() -> FluxData? {
        guard let userDefaults = UserDefaults(suiteName: Self.appGroupID) else {
            return nil
        }
        guard let data = userDefaults.data(forKey: "fluxData") else {
            return nil
        }
        return try? JSONDecoder().decode(FluxData.self, from: data)
    }
    
    private func fetchFluxDataFromServer(completion: @escaping (FluxData?) -> Void) {
        guard let userDefaults = UserDefaults(suiteName: Self.appGroupID),
              let serverURL = userDefaults.string(forKey: "serverURL"),
              let authToken = userDefaults.string(forKey: "authToken"),
              !serverURL.isEmpty,
              !authToken.isEmpty else {
            completion(nil)
            return
        }
        
        let urlString = serverURL + "/api/v1/user/package"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        request.httpBody = "{}".data(using: .utf8)
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let code = json["code"] as? Int,
                  code == 0,
                  let dataDict = json["data"] as? [String: Any] else {
                completion(nil)
                return
            }
            
            // 解析 userInfo
            let userInfo = dataDict["userInfo"] as? [String: Any] ?? dataDict
            
            let flow = (userInfo["flow"] as? Int64) ?? Int64(userInfo["flow"] as? Int ?? 0)
            let inFlow = (userInfo["inFlow"] as? Int64) ?? Int64(userInfo["inFlow"] as? Int ?? 0)
            let outFlow = (userInfo["outFlow"] as? Int64) ?? Int64(userInfo["outFlow"] as? Int ?? 0)
            let expTime = userInfo["expTime"] as? String
            
            let fluxData = FluxData(
                totalFlow: flow,
                usedFlow: inFlow + outFlow,
                expTime: expTime,
                serverURL: serverURL,
                lastUpdate: Date()
            )
            
            // 保存到 App Groups
            if let encoded = try? JSONEncoder().encode(fluxData) {
                userDefaults.set(encoded, forKey: "fluxData")
            }
            
            completion(fluxData)
        }.resume()
    }
}

// MARK: - Timeline Entry

struct FluxEntry: TimelineEntry {
    let date: Date
    let data: FluxData?
    let isPlaceholder: Bool
}

// MARK: - Widget Views

struct FluxWidgetEntryView: View {
    var entry: FluxProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: FluxEntry
    
    var body: some View {
        VStack(spacing: 6) {
            if let data = entry.data {
                // 圆形进度条 + 百分比
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    
                    if !data.isUnlimited {
                        Circle()
                            .trim(from: 0, to: data.usagePercentage)
                            .stroke(
                                data.usagePercentage > 0.9 ? Color.red : Color.blue,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                    }
                    
                    // 百分比
                    Text(data.isUnlimited ? "∞" : "\(Int(data.usagePercentage * 100))%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .frame(width: 70, height: 70)
                
                // 已用流量 - 大字体
                Text(data.formattedUsedFlow)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                
                // 总量
                Text(data.formattedTotalFlow)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 28))
                    .foregroundColor(.orange)
                Text("请先登录")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
    }
}

struct MediumWidgetView: View {
    let entry: FluxEntry
    
    var body: some View {
        if let data = entry.data {
            HStack(spacing: 20) {
                // 左侧：已用流量
                VStack(spacing: 4) {
                    Text(data.formattedUsedFlow)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    
                    Text(data.formattedTotalFlow)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                // 右侧：详细信息
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "percent")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text(data.isUnlimited ? "N/A" : "\(Int(data.usagePercentage * 100))%")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text(data.formattedExpTime)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(data.isExpired ? .red : .primary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
        } else {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text("未登录")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("请打开 Flux 应用登录")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

struct CircularWidgetView: View {
    let entry: FluxEntry
    
    var body: some View {
        if let data = entry.data {
            if data.isUnlimited {
                VStack(spacing: 2) {
                    Image(systemName: "infinity")
                        .font(.system(size: 16, weight: .bold))
                    Text(data.formattedUsedFlow)
                        .font(.system(size: 10, weight: .medium))
                        .minimumScaleFactor(0.6)
                }
            } else {
                Gauge(value: data.usagePercentage) {
                    Image(systemName: "arrow.up.arrow.down")
                } currentValueLabel: {
                    Text("\(Int(data.usagePercentage * 100))%")
                        .font(.system(size: 12, weight: .semibold))
                }
                .gaugeStyle(.accessoryCircular)
            }
        } else {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 24))
        }
    }
}

struct RectangularWidgetView: View {
    let entry: FluxEntry
    
    var body: some View {
        if let data = entry.data {
            VStack(alignment: .leading, spacing: 4) {
                Text(data.formattedUsedFlow)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                if data.isUnlimited {
                    Text("Unlimited")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                } else {
                    ProgressView(value: data.usagePercentage)
                        .progressViewStyle(.linear)
                    
                    Text(data.formattedTotalFlow)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        } else {
            Text("请登录 Flux")
                .font(.system(size: 14))
        }
    }
}

// MARK: - Widget Configuration

@main
struct FluxWidget: Widget {
    let kind: String = "FluxWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FluxProvider()) { entry in
            FluxWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Flux 流量")
        .description("显示已用流量和套餐信息")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    FluxWidget()
} timeline: {
    FluxEntry(date: .now, data: FluxData(
        totalFlow: 100,
        usedFlow: 53_687_091_200, // 50 GB
        expTime: "2026-02-01T00:00:00",
        serverURL: "https://example.com",
        lastUpdate: Date()
    ), isPlaceholder: false)
    
    FluxEntry(date: .now, data: FluxData(
        totalFlow: 0, // Unlimited
        usedFlow: 53_687_091_200,
        expTime: nil,
        serverURL: "https://example.com",
        lastUpdate: Date()
    ), isPlaceholder: false)
    
    FluxEntry(date: .now, data: nil, isPlaceholder: false)
}

#Preview(as: .systemMedium) {
    FluxWidget()
} timeline: {
    FluxEntry(date: .now, data: FluxData(
        totalFlow: 100,
        usedFlow: 53_687_091_200,
        expTime: "2026-02-01T00:00:00",
        serverURL: "https://example.com",
        lastUpdate: Date()
    ), isPlaceholder: false)
    
    FluxEntry(date: .now, data: FluxData(
        totalFlow: 0, // Unlimited
        usedFlow: 123_456_789_012,
        expTime: nil,
        serverURL: "https://example.com",
        lastUpdate: Date()
    ), isPlaceholder: false)
}
