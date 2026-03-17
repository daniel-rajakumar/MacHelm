import Foundation
import Combine

struct BrewCask: Codable, Identifiable {
    var id: String { token }
    let token: String
    let name: [String]
    let desc: String?
    let version: String?
    let homepage: String?

    var iconURL: URL? {
        guard let urlString = homepage,
              let url = URL(string: urlString),
              let host = url.host else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=128")
    }
}

class StoreManager: ObservableObject {
    @Published var casks: [BrewCask] = []
    @Published var filteredCasks: [BrewCask] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let apiURL = "https://formulae.brew.sh/api/cask.json"
    
    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) {
        if query.isEmpty {
            self.filteredCasks = Array(self.casks.prefix(200)) // Truncate to prevent rendering lag
            return
        }
        
        let lowerQuery = query.localizedLowercase
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let filtered = self.casks.filter { cask in
                cask.token.localizedLowercase.contains(lowerQuery) ||
                cask.name.contains(where: { $0.localizedLowercase.contains(lowerQuery) }) ||
                (cask.desc?.localizedLowercase.contains(lowerQuery) ?? false)
            }
            let topResults = Array(filtered.prefix(100))
            DispatchQueue.main.async {
                self.filteredCasks = topResults
            }
        }
    }
    
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
                    self?.performSearch(query: self?.searchText ?? "")
                } catch {
                    self?.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                    print("Decoding error: \(error)")
                }
            }
        }.resume()
    }
}
