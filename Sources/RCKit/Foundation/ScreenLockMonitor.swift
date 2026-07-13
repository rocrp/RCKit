#if os(macOS)
    import Foundation
    import Observation

    @MainActor
    @Observable
    public final class ScreenLockMonitor {
        public private(set) var isLocked = false

        @ObservationIgnored private let notificationSource: NotificationSource
        @ObservationIgnored private var lockObserver: (any NSObjectProtocol)?
        @ObservationIgnored private var unlockObserver: (any NSObjectProtocol)?

        public convenience init() {
            self.init(notificationSource: NotificationSource(DistributedNotificationCenter.default()))
        }

        public convenience init(notificationCenter: NotificationCenter) {
            self.init(notificationSource: NotificationSource(notificationCenter))
        }

        private init(notificationSource: NotificationSource) {
            self.notificationSource = notificationSource
            lockObserver = notificationSource.addObserver(name: .init("com.apple.screenIsLocked")) { [weak self] in
                Task { @MainActor [weak self] in
                    self?.isLocked = true
                }
            }
            unlockObserver = notificationSource.addObserver(name: .init("com.apple.screenIsUnlocked")) { [weak self] in
                Task { @MainActor [weak self] in
                    self?.isLocked = false
                }
            }
        }

        isolated deinit {
            if let lockObserver {
                notificationSource.removeObserver(lockObserver)
            }
            if let unlockObserver {
                notificationSource.removeObserver(unlockObserver)
            }
        }
    }

    private struct NotificationSource: @unchecked Sendable {
        private let add: @Sendable (Notification.Name, @escaping @Sendable () -> Void) -> any NSObjectProtocol
        private let remove: @Sendable (any NSObjectProtocol) -> Void

        init(_ center: NotificationCenter) {
            add = { name, handler in
                center.addObserver(forName: name, object: nil, queue: .main) { _ in
                    handler()
                }
            }
            remove = { observer in
                center.removeObserver(observer)
            }
        }

        init(_ center: DistributedNotificationCenter) {
            add = { name, handler in
                center.addObserver(forName: name, object: nil, queue: .main) { _ in
                    handler()
                }
            }
            remove = { observer in
                center.removeObserver(observer)
            }
        }

        func addObserver(
            name: Notification.Name,
            handler: @escaping @Sendable () -> Void
        ) -> any NSObjectProtocol {
            add(name, handler)
        }

        func removeObserver(_ observer: any NSObjectProtocol) {
            remove(observer)
        }
    }
#endif
