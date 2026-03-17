import Foundation

class DirectoryWatcher {
    private let url: URL
    private let callback: () -> Void
    private var fileDescriptor: Int32 = -1
    private var source: DispatchSourceFileSystemObject?
    private let queue = DispatchQueue(label: "com.machelm.directorywatcher")

    init(url: URL, callback: @escaping () -> Void) {
        self.url = url
        self.callback = callback
    }

    func start() {
        guard fileDescriptor == -1 else { return }

        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor != -1 else {
            print("Failed to open directory for watching: \(url.path)")
            return
        }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: queue
        )

        source?.setEventHandler { [weak self] in
            self?.callback()
        }

        source?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
            self.source = nil
        }

        source?.resume()
    }

    func stop() {
        source?.cancel()
    }

    deinit {
        stop()
    }
}
