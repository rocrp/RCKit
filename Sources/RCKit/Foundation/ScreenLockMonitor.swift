#if os(macOS)
    import Foundation
    import Observation

    @MainActor
    @Observable
    public final class ScreenLockMonitor {
        public private(set) var isLocked = false
        public var onLockStateChange: ((Bool) -> Void)?

        @ObservationIgnored nonisolated(unsafe) private var lockObserver: Any?
        @ObservationIgnored nonisolated(unsafe) private var unlockObserver: Any?

        public init() {
            let center = DistributedNotificationCenter.default()
            lockObserver = center.addObserver(
                forName: .init("com.apple.screenIsLocked"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.setLockState(true)
                }
            }
            unlockObserver = center.addObserver(
                forName: .init("com.apple.screenIsUnlocked"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.setLockState(false)
                }
            }
        }

        private func setLockState(_ isLocked: Bool) {
            self.isLocked = isLocked
            onLockStateChange?(isLocked)
        }

        deinit {
            let center = DistributedNotificationCenter.default()
            if let lockObserver {
                center.removeObserver(lockObserver)
            }
            if let unlockObserver {
                center.removeObserver(unlockObserver)
            }
        }
    }
#endif
