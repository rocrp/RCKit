#if os(macOS)
    import Foundation
    import Synchronization
    import Testing

    @testable import RCKit

    struct ScreenLockMonitorTests {
        @MainActor
        @Test func injectedNotificationsDriveTheSingleLockStateOutput() async {
            let center = NotificationCenter()
            let monitor = ScreenLockMonitor(notificationCenter: center)

            center.post(name: .init("com.apple.screenIsLocked"), object: nil)
            await Task.yield()
            #expect(monitor.isLocked)

            center.post(name: .init("com.apple.screenIsUnlocked"), object: nil)
            await Task.yield()
            #expect(!monitor.isLocked)
        }

        @MainActor
        @Test func deinitRemovesBothObservers() {
            let center = TrackingNotificationCenter()
            weak var weakMonitor: ScreenLockMonitor?

            do {
                let monitor = ScreenLockMonitor(notificationCenter: center)
                weakMonitor = monitor
                #expect(center.removalCount == 0)
            }

            #expect(weakMonitor == nil)
            #expect(center.removalCount == 2)
        }
    }

    private final class TrackingNotificationCenter: NotificationCenter, @unchecked Sendable {
        private let removals = Mutex(0)

        var removalCount: Int {
            removals.withLock { $0 }
        }

        override func removeObserver(_ observer: Any) {
            removals.withLock { $0 += 1 }
            super.removeObserver(observer)
        }
    }
#endif
