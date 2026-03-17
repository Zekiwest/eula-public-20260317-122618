import SwiftUI
import UIKit
import Combine

private struct TabBarHiddenBindingKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}

private struct SelectedNavTabKey: EnvironmentKey {
    static let defaultValue: NavTab? = nil
}

private struct SelectedNavTabBindingKey: EnvironmentKey {
    static let defaultValue: Binding<NavTab>? = nil
}

private struct BanUserActionKey: EnvironmentKey {
    static let defaultValue: ((BanUserTarget) -> Void)? = nil
}

private struct BlockedUsersStoreKey: EnvironmentKey {
    static let defaultValue: BlockedUsersStore? = nil
}

struct BanUserTarget: Identifiable, Hashable {
    let id: String
    let name: String
    let avatarName: String
}

final class BlockedUsersStore: ObservableObject {
    @Published var users: [BanUserTarget] = []
    @Published private(set) var blockedUserIDs: Set<String> = []
    
    private var currentUserId: String?
    private let defaults = UserDefaults.standard

    func isBlocked(_ userId: String) -> Bool {
        blockedUserIDs.contains(userId)
    }

    func block(_ user: BanUserTarget) {
        guard !isBlocked(user.id) else { return }
        users.append(user)
        blockedUserIDs.insert(user.id)
        syncToServer(isBlocking: true, targetUserId: user.id)
        saveToLocalCache()
    }

    func unblock(_ userId: String) {
        users.removeAll(where: { $0.id == userId })
        blockedUserIDs.remove(userId)
        syncToServer(isBlocking: false, targetUserId: userId)
        saveToLocalCache()
    }
    
    func setCurrentUserId(_ userId: String?) {
        if currentUserId != userId {
            currentUserId = userId
            users = []
            blockedUserIDs = []
        } else {
            currentUserId = userId
        }
    }
    
    func loadFromServer(userId: String) async {
        do {
            let accessToken = AuthManager.shared.accessToken
            let bearerToken = accessToken?.split(separator: ".").count == 3 ? accessToken : nil
            let blockedIds = try await UserRelationsService.shared.getBlockedList(userId: userId, accessToken: bearerToken)
            await MainActor.run {
                self.blockedUserIDs = blockedIds
                self.users = blockedIds.compactMap { id in
                    MockUsers.all.first { $0.id == id }.map {
                        BanUserTarget(id: id, name: $0.name, avatarName: $0.avatarName)
                    }
                }
            }
            UserRelationsService.shared.cacheBlockedList(blockedIds, forUserId: userId)
        } catch {
            if let cached = UserRelationsService.shared.loadCachedBlockedList(userId: userId) {
                await MainActor.run {
                    self.blockedUserIDs = cached
                    self.users = cached.compactMap { id in
                        MockUsers.all.first { $0.id == id }.map {
                            BanUserTarget(id: id, name: $0.name, avatarName: $0.avatarName)
                        }
                    }
                }
            } else {
                await MainActor.run {
                    self.blockedUserIDs = []
                    self.users = []
                }
            }
        }
    }
    
    private func syncToServer(isBlocking: Bool, targetUserId: String) {
        guard let userId = currentUserId else { return }
        Task {
            do {
                let accessToken = AuthManager.shared.accessToken
                let bearerToken = accessToken?.split(separator: ".").count == 3 ? accessToken : nil
                if isBlocking {
                    try await UserRelationsService.shared.addBlock(userId: userId, targetUserId: targetUserId, accessToken: bearerToken)
                } else {
                    try await UserRelationsService.shared.removeBlock(userId: userId, targetUserId: targetUserId, accessToken: bearerToken)
                }
            } catch {
            }
        }
    }
    
    private func saveToLocalCache() {
        guard let userId = currentUserId else { return }
        UserRelationsService.shared.cacheBlockedList(blockedUserIDs, forUserId: userId)
    }
}

final class ChatListStore: ObservableObject {
    @Published var items: [MessageItem] = []

    func ensureChat(for user: BanUserTarget) {
        let personaKey = makePersonaKey(from: user.name)

        if let index = items.firstIndex(where: { $0.personaKey == personaKey }) {
            let old = items[index]
            let updated = MessageItem(
                id: old.id,
                name: user.name,
                message: old.message,
                avatar: user.avatarName,
                unreadCount: old.unreadCount,
                personaKey: personaKey,
                userId: user.id
            )
            items.remove(at: index)
            items.insert(updated, at: 0)
        } else {
            let nextID = (items.map { $0.id }.max() ?? 0) + 1
            let newItem = MessageItem(
                id: nextID,
                name: user.name,
                message: "Tap to start chatting.",
                avatar: user.avatarName,
                unreadCount: 0,
                personaKey: personaKey,
                userId: user.id
            )
            items.insert(newItem, at: 0)
        }
    }

    private func makePersonaKey(from name: String) -> String {
        let parts = name
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return parts.joined()
    }
}

final class ProfileStatsStore: ObservableObject {
    struct Stats {
        var followingCount: Int
        var fansCount: Int
    }

    @Published private(set) var myStats: Stats
    @Published private var otherStatsByUserID: [String: Stats]
    @Published private(set) var followedUserIDs: Set<String>
    @Published private(set) var fansUserIDs: Set<String>
    
    private var currentUserId: String?

    init() {
        myStats = Stats(followingCount: 0, fansCount: 0)
        otherStatsByUserID = [:]
        followedUserIDs = []
        fansUserIDs = []
    }
    
    var followingUsersList: [RelationshipUser] {
        followedUserIDs.compactMap { userId -> RelationshipUser? in
            guard let user = MockUsers.find(byId: userId) else { return nil }
            return RelationshipUser(id: userId, user: user, status: "Following")
        }
    }
    
    var fansUsersList: [RelationshipUser] {
        fansUserIDs.compactMap { userId -> RelationshipUser? in
            guard let user = MockUsers.find(byId: userId) else { return nil }
            let isFollowed = followedUserIDs.contains(userId)
            return RelationshipUser(id: userId, user: user, status: isFollowed ? "Following" : "Follow")
        }
    }

    func stats(for user: BanUserTarget) -> Stats {
        ensureStats(for: user)
    }

    func isFollowing(_ user: BanUserTarget) -> Bool {
        followedUserIDs.contains(user.id)
    }

    func isMutualFollowing(_ userId: String) -> Bool {
        let iFollowThem = followedUserIDs.contains(userId)
        let theyFollowMe = fansUserIDs.contains(userId)
        return iFollowThem && theyFollowMe
    }

    func toggleFollow(user: BanUserTarget) {
        let shouldFollow = !isFollowing(user)
        if shouldFollow {
            followedUserIDs.insert(user.id)
            myStats.followingCount += 1
            var stats = ensureStats(for: user)
            stats.fansCount += 1
            otherStatsByUserID[user.id] = stats
            syncToServer(isFollowing: true, targetUserId: user.id)
        } else {
            followedUserIDs.remove(user.id)
            myStats.followingCount = max(0, myStats.followingCount - 1)
            var stats = ensureStats(for: user)
            stats.fansCount = max(0, stats.fansCount - 1)
            otherStatsByUserID[user.id] = stats
            syncToServer(isFollowing: false, targetUserId: user.id)
        }
        saveToLocalCache()
    }
    
    func setCurrentUserId(_ userId: String?) {
        if currentUserId != userId {
            currentUserId = userId
            followedUserIDs = []
            fansUserIDs = []
            myStats = Stats(followingCount: 0, fansCount: 0)
            otherStatsByUserID = [:]
        } else {
            currentUserId = userId
        }
    }

    func displayCount(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic))
    }
    
    func loadFromServer(userId: String) async {
        do {
            let accessToken = AuthManager.shared.accessToken
            let bearerToken = accessToken?.split(separator: ".").count == 3 ? accessToken : nil
            let followingIds = try await UserRelationsService.shared.getFollowingList(userId: userId, accessToken: bearerToken)
            await MainActor.run {
                self.followedUserIDs = followingIds
                self.myStats.followingCount = followingIds.count
            }
            UserRelationsService.shared.cacheFollowingList(followingIds, forUserId: userId)
        } catch {
            if let cached = UserRelationsService.shared.loadCachedFollowingList(userId: userId) {
                await MainActor.run {
                    self.followedUserIDs = cached
                    self.myStats.followingCount = cached.count
                }
            } else {
                await MainActor.run {
                    self.followedUserIDs = []
                    self.myStats.followingCount = 0
                }
            }
        }
    }

    private func ensureStats(for user: BanUserTarget) -> Stats {
        if let stats = otherStatsByUserID[user.id] {
            return stats
        }
        let seed = MockSeed.stableInt(user.id)
        let generated = Stats(
            followingCount: 80 + (seed % 620),
            fansCount: MockSeed.followerCount(seed: seed)
        )
        otherStatsByUserID[user.id] = generated
        return generated
    }
    
    private func syncToServer(isFollowing: Bool, targetUserId: String) {
        guard let userId = currentUserId else { return }
        Task {
            do {
                let accessToken = AuthManager.shared.accessToken
                let bearerToken = accessToken?.split(separator: ".").count == 3 ? accessToken : nil
                if isFollowing {
                    try await UserRelationsService.shared.addFollow(userId: userId, targetUserId: targetUserId, accessToken: bearerToken)
                } else {
                    try await UserRelationsService.shared.removeFollow(userId: userId, targetUserId: targetUserId, accessToken: bearerToken)
                }
            } catch {
            }
        }
    }
    
    private func saveToLocalCache() {
        guard let userId = currentUserId else { return }
        UserRelationsService.shared.cacheFollowingList(followedUserIDs, forUserId: userId)
    }
}

extension EnvironmentValues {
    var tabBarHiddenBinding: Binding<Bool>? {
        get { self[TabBarHiddenBindingKey.self] }
        set { self[TabBarHiddenBindingKey.self] = newValue }
    }

    var selectedNavTab: NavTab? {
        get { self[SelectedNavTabKey.self] }
        set { self[SelectedNavTabKey.self] = newValue }
    }

    var selectedNavTabBinding: Binding<NavTab>? {
        get { self[SelectedNavTabBindingKey.self] }
        set { self[SelectedNavTabBindingKey.self] = newValue }
    }
    
    var banUserAction: ((BanUserTarget) -> Void)? {
        get { self[BanUserActionKey.self] }
        set { self[BanUserActionKey.self] = newValue }
    }

    var blockedUsersStore: BlockedUsersStore? {
        get { self[BlockedUsersStoreKey.self] }
        set { self[BlockedUsersStoreKey.self] = newValue }
    }
}

extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct TabBarVisibilitySync: View {
    @Environment(\.tabBarHiddenBinding) private var tabBarHiddenBinding
    let isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    var body: some View {
        NavigationControllerObserver(tabBarHiddenBinding: tabBarHiddenBinding, isEnabled: isEnabled)
            .frame(width: 0, height: 0)
    }
}

private struct NavigationControllerObserver: UIViewControllerRepresentable {
    let tabBarHiddenBinding: Binding<Bool>?
    let isEnabled: Bool

    func makeUIViewController(context: Context) -> ObserverViewController {
        let controller = ObserverViewController()
        controller.onResolveNavigationController = { navigationController in
            context.coordinator.attach(to: navigationController, tabBarHiddenBinding: tabBarHiddenBinding, isEnabled: isEnabled)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: ObserverViewController, context: Context) {
        context.coordinator.update(tabBarHiddenBinding: tabBarHiddenBinding, isEnabled: isEnabled)
        uiViewController.onResolveNavigationController = { navigationController in
            context.coordinator.attach(to: navigationController, tabBarHiddenBinding: tabBarHiddenBinding, isEnabled: isEnabled)
        }
        uiViewController.resolveNavigationControllerIfPossible()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private weak var navigationController: UINavigationController?
        private var observation: NSKeyValueObservation?
        private var tabBarHiddenBinding: Binding<Bool>?
        private var isEnabled: Bool = true

        func update(tabBarHiddenBinding: Binding<Bool>?, isEnabled: Bool) {
            self.tabBarHiddenBinding = tabBarHiddenBinding
            let wasEnabled = self.isEnabled
            self.isEnabled = isEnabled
            guard isEnabled else { return }
            if wasEnabled != isEnabled {
                syncIfPossible()
            }
        }

        func attach(to navigationController: UINavigationController?, tabBarHiddenBinding: Binding<Bool>?, isEnabled: Bool) {
            update(tabBarHiddenBinding: tabBarHiddenBinding, isEnabled: isEnabled)
            guard let navigationController else { return }
            guard self.navigationController !== navigationController else {
                syncIfPossible()
                return
            }

            self.navigationController = navigationController
            observation?.invalidate()
            observation = navigationController.observe(\.viewControllers, options: [.initial, .new]) { [weak self] navigationController, _ in
                self?.sync(navigationController)
            }
        }

        private func syncIfPossible() {
            guard isEnabled else { return }
            guard let navigationController else { return }
            sync(navigationController)
        }

        private func sync(_ navigationController: UINavigationController) {
            guard isEnabled else { return }
            let shouldHide = navigationController.viewControllers.count > 1
            guard tabBarHiddenBinding?.wrappedValue != shouldHide else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tabBarHiddenBinding?.wrappedValue = shouldHide
            }
        }
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    let scale: CGFloat
    let opacity: CGFloat

    init(scale: CGFloat = 0.95, opacity: CGFloat = 1.0) {
        self.scale = scale
        self.opacity = opacity
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? opacity : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

struct DefaultAvatarView: View {
    var size: CGFloat = 40
    var backgroundColor: Color = Color(hexString: "ACB1D7")
    var iconColor: Color = .white
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
            
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundStyle(iconColor)
        }
        .frame(width: size, height: size)
    }
}

struct UserAvatarView: View {
    var avatarName: String?
    var avatarUrl: String?
    var size: CGFloat = 40
    var showBorder: Bool = true
    
    private var hasCustomAvatar: Bool {
        if let url = avatarUrl, !url.isEmpty { return true }
        if let name = avatarName, !name.isEmpty { return true }
        return false
    }
    
    var body: some View {
        Group {
            if hasCustomAvatar {
                if let url = avatarUrl, !url.isEmpty {
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure, .empty:
                            DefaultAvatarView(size: size)
                        @unknown default:
                            DefaultAvatarView(size: size)
                        }
                    }
                } else if let name = avatarName, !name.isEmpty {
                    Image(name)
                        .resizable()
                        .scaledToFill()
                }
            } else {
                DefaultAvatarView(size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            if showBorder {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color(hexString: "FF8796"), Color(hexString: "F7B257")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
    }
}

private final class ObserverViewController: UIViewController {
    var onResolveNavigationController: ((UINavigationController?) -> Void)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resolveNavigationControllerIfPossible()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        resolveNavigationControllerIfPossible()
    }

    func resolveNavigationControllerIfPossible() {
        onResolveNavigationController?(navigationController)
    }
}
