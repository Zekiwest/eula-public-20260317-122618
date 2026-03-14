
import SwiftUI
import UIKit

/**
 * [INPUT]: 依赖 Assets 与 MainTabIcons.json 的图标映射
 * [OUTPUT]: 对外提供 MainTabView 组件
 * [POS]: UI/MainTabView.swift - 应用的主导航栏
 * [SWIFTUI_STATE]: @Binding var selectedTab: NavTab - 控制当前选中的 Tab
 * [SWIFTUI_PREVIEWS]: struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        Group { MainTabView(selectedTab: .constant(.home)) }
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */
private struct TabIconPair: Decodable {
    let off: String
    let on: String
    let offSize: Double?
    let onSize: Double?
}

private struct TabIconMap: Decodable {
    let tabs: [String: TabIconPair]
    let add: String?
    let addSize: Double?
}

private enum TabIconConfigLoader {
    static func load() -> TabIconMap? {
        guard let url = Bundle.main.url(forResource: "MainTabIcons", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(TabIconMap.self, from: data)
    }
}

struct MainTabView: View {
    @Binding var selectedTab: NavTab
    let onAddTap: () -> Void
    
    // Figma Dimensions
    private let containerWidth: CGFloat = 327
    private let containerHeight: CGFloat = 56
    
    private static let iconMapCache = TabIconConfigLoader.load()

    init(selectedTab: Binding<NavTab>, onAddTap: @escaping () -> Void = { }) {
        self._selectedTab = selectedTab
        self.onAddTap = onAddTap
    }

    var body: some View {
        ZStack {
            tabBarBackground
                .allowsHitTesting(false)

            tabButtons
        }
        .frame(width: containerWidth, height: containerHeight)
    }

    private var tabButtons: some View {
        HStack(spacing: 0) {
            ForEach(orderedTabs, id: \.self) { tab in
                let config = iconConfig(for: tab)
                TabItem(
                    tab: tab,
                    selectedTab: $selectedTab,
                    onTapOverride: tab == .add ? onAddTap : nil,
                    iconOff: config.off,
                    iconOn: config.on,
                    enableSelectionEffect: config.enableSelectionEffect,
                    offSize: config.offSize,
                    onSize: config.onSize
                )
            }
        }
        .frame(width: containerWidth, height: containerHeight)
    }

    @ViewBuilder
    private var tabBarBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        if #available(iOS 26, *) {
            ZStack {
                Color.black.opacity(0.1)
                Color.clear
                    .glassEffect(in: shape)
                shape
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            }
            .frame(width: containerWidth, height: containerHeight)
            .clipShape(shape)
        } else {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Color.black.opacity(0.1)
                shape
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            }
            .frame(width: containerWidth, height: containerHeight)
            .clipShape(shape)
        }
    }

    private var orderedTabs: [NavTab] {
        [.home, .shorts, .add, .messages, .profile]
    }

    private func iconConfig(for tab: NavTab) -> (off: String, on: String, enableSelectionEffect: Bool, offSize: CGFloat, onSize: CGFloat) {
        let base = tab.rawValue
        if tab == .add {
            if let name = MainTabView.iconMapCache?.add, !name.isEmpty {
                let size = iconSize(MainTabView.iconMapCache?.addSize, fallback: 40)
                return (off: name, on: name, enableSelectionEffect: false, offSize: size, onSize: size)
            }
            let name = resolveIconName(base: base, state: nil)
            return (off: name, on: name, enableSelectionEffect: false, offSize: 40, onSize: 40)
        }
        if let pair = MainTabView.iconMapCache?.tabs[base] {
            let offSize = iconSize(pair.offSize, fallback: 40)
            let onSize = iconSize(pair.onSize, fallback: 68)
            return (off: pair.off, on: pair.on, enableSelectionEffect: true, offSize: offSize, onSize: onSize)
        }
        let off = resolveIconName(base: base, state: "off")
        let on = resolveIconName(base: base, state: "on")
        return (off: off, on: on, enableSelectionEffect: true, offSize: 40, onSize: 68)
    }

    private func resolveIconName(base: String, state: String?) -> String {
        let candidates: [String]
        if let state {
            candidates = ["tab_\(base)_\(state)", "\(base)_\(state)"]
        } else {
            candidates = ["tab_\(base)", base]
        }
        return candidates.first(where: assetExists) ?? candidates.first ?? base
    }

    private func assetExists(_ name: String) -> Bool {
        UIImage(named: name) != nil
    }

    private func iconSize(_ value: Double?, fallback: CGFloat) -> CGFloat {
        guard let value, value > 0 else {
            return fallback
        }
        return CGFloat(value)
    }
}

struct TabItem: View {
    let tab: NavTab
    @Binding var selectedTab: NavTab
    var onTapOverride: (() -> Void)?
    let iconOff: String
    let iconOn: String
    var enableSelectionEffect: Bool = true
    let offSize: CGFloat
    let onSize: CGFloat
    
    var isSelected: Bool {
        selectedTab == tab
    }
    
    var body: some View {
        Button {
            if let onTapOverride {
                onTapOverride()
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = tab
                }
            }
        } label: {
            // 布局层：完全透明的刚性骨架，确保布局绝对稳定
            Color.clear
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .overlay {
                    // 内容层：悬浮于骨架之上，尺寸变化不影响布局
                    if isSelected && enableSelectionEffect {
                        // 选中态：直接展示 iconOn，移除 Shadow
                        Image(iconOn)
                            .resizable()
                            .scaledToFit()
                            .frame(width: onSize, height: onSize)
                    } else {
                        // 普通态
                        Image(isSelected ? iconOn : iconOff)
                            .resizable()
                            .scaledToFit()
                            .frame(width: offSize, height: offSize)
                    }
                }
        }
        .accessibilityIdentifier("tab_\(tab.rawValue)")
        .accessibilityLabel(tab.title)
        .buttonStyle(.plain)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    ZStack {
        Color.gray
        MainTabView(selectedTab: .constant(.home))
    }
}
    }
}
