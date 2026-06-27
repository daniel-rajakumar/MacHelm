import Foundation

struct SystemTaskRunner {
    static func runScript(named scriptName: String, arguments: [String] = [], completion: @escaping (Bool) -> Void) {
        let process = Process()
        let scriptPath = "/Users/danielrajakumar/code/MacHelm/scripts/system/\(scriptName)"

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["bash", scriptPath] + arguments

        process.terminationHandler = { process in
            DispatchQueue.main.async {
                completion(process.terminationStatus == 0)
            }
        }

        do {
            try process.run()
        } catch {
            print("Failed to run script: \(error)")
            completion(false)
        }
    }
}
