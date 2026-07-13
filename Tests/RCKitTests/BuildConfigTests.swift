import Testing

@testable import RCKit

struct BuildConfigTests {
    @Test func resolvesEveryChannelFromExplicitInputs() {
        #expect(BuildConfig.resolveChannel(isDebugBuild: true, hasSandboxReceipt: false) == .debug)
        #expect(BuildConfig.resolveChannel(isDebugBuild: false, hasSandboxReceipt: true) == .testflight)
        #expect(BuildConfig.resolveChannel(isDebugBuild: false, hasSandboxReceipt: false) == .appstore)
    }

    @Test func resolverProbesAndResolvesOnlyOnce() async {
        let probe = SuspendingChannelProbe(hasSandboxReceipt: true)
        let resolver = BuildConfig.ChannelResolver(isDebugBuild: false, probe: probe)

        let first = Task { await resolver.resolve() }
        await probe.waitUntilCalled()

        let second = Task { await resolver.resolve() }
        let third = Task { await resolver.resolve() }
        #expect(await probe.callCount == 1)

        await probe.release()
        let values = await [first.value, second.value, third.value]

        #expect(values == [.testflight, .testflight, .testflight])
        #expect(await probe.callCount == 1)
        #expect(await resolver.resolve() == .testflight)
        #expect(await probe.callCount == 1)
    }

    @Test func debugResolverDoesNotProbeReceipt() async {
        let probe = CountingChannelProbe(hasSandboxReceipt: true)
        let resolver = BuildConfig.ChannelResolver(isDebugBuild: true, probe: probe)

        #expect(await resolver.resolve() == .debug)
        #expect(await probe.callCount == 0)
    }
}

private actor SuspendingChannelProbe: BuildConfig.ChannelProbe {
    let hasSandboxReceipt: Bool
    private(set) var callCount = 0
    private var continuation: CheckedContinuation<Void, Never>?

    init(hasSandboxReceipt: Bool) {
        self.hasSandboxReceipt = hasSandboxReceipt
    }

    func isSandboxReceipt() async -> Bool {
        callCount += 1
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
        return hasSandboxReceipt
    }

    func waitUntilCalled() async {
        while callCount == 0 {
            await Task.yield()
        }
    }

    func release() {
        guard let continuation else {
            preconditionFailure("Channel Probe released before it suspended")
        }

        self.continuation = nil
        continuation.resume()
    }
}

private actor CountingChannelProbe: BuildConfig.ChannelProbe {
    let hasSandboxReceipt: Bool
    private(set) var callCount = 0

    init(hasSandboxReceipt: Bool) {
        self.hasSandboxReceipt = hasSandboxReceipt
    }

    func isSandboxReceipt() async -> Bool {
        callCount += 1
        await Task.yield()
        return hasSandboxReceipt
    }
}
