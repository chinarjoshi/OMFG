import Foundation

final class AutoSaveController {
    private let debounceInterval: TimeInterval
    private var pendingWorkItem: DispatchWorkItem?
    private let queue = DispatchQueue(label: "autosave", qos: .utility)

    init(debounceInterval: TimeInterval = 0.5) {
        self.debounceInterval = debounceInterval
    }

    func scheduleWrite(content: String, to url: URL) {
        pendingWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }

        pendingWorkItem = workItem
        queue.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }

    func flushImmediately() {
        pendingWorkItem?.perform()
        pendingWorkItem = nil
    }
}
