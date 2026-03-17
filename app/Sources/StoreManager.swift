import Foundation
import Combine

struct BrewCask: Codable, Identifiable {
    var id: String { token }
    let token: String
    let name: [String]
    let desc: String?
    let version: String?
    let homepage: String?
}

class StoreManager: ObservableObject {
    @Published var casks: [BrewCask] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let apiURL = "https://formulae.brew.sh/api/cask.json"
    
    func fetchCasks() {
        guard casks.isEmpty else { return } // Only load once per session
        
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: apiURL) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid API URL"
                self.isLoading = false
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let decodedCasks = try JSONDecoder().decode([BrewCask].self, from: data)
                    self?.casks = decodedCasks
                } catch {
                    self?.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                    print("Decoding error: \(error)")
                }
            }
        }.resume()
    }
}
