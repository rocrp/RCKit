import RCKit

/// Process-wide Destinations shared by both demo apps and their logging screen.
public enum DemoLogging {
    public static let memoryDestination = MemoryDestination()

    private static let fileState: FileState = {
        do {
            return .available(try FileDestination(prefix: "demo"))
        } catch {
            return .unavailable(error.localizedDescription)
        }
    }()

    public static var destinations: [any LogDestination] {
        switch fileState {
        case .available(let destination):
            [memoryDestination, destination]
        case .unavailable:
            [memoryDestination]
        }
    }

    public static var fileDestination: FileDestination? {
        guard case .available(let destination) = fileState else { return nil }
        return destination
    }

    public static var fileDestinationError: String? {
        guard case .unavailable(let message) = fileState else { return nil }
        return message
    }

    private enum FileState: Sendable {
        case available(FileDestination)
        case unavailable(String)
    }
}
