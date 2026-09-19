import Foundation

actor SupabaseWordRepository {
    private static let pageSize = 1_000
    private static let minimumWordsPerDifficulty = 8
    private static let cacheFileName = "word-catalog-v1.json"

    private let configuration: SupabaseConfiguration?
    private let session: URLSession
    private let fileManager: FileManager

    init(
        configuration: SupabaseConfiguration? = SupabaseConfiguration.bundled,
        session: URLSession = .shared,
        fileManager: FileManager = .default
    ) {
        self.configuration = configuration
        self.session = session
        self.fileManager = fileManager
    }

    func loadCatalog() async -> [Difficulty: [WordEntry]]? {
        if let configuration {
            do {
                let remoteWords = try await fetchAllWords(using: configuration)
                let catalog = try validatedCatalog(from: remoteWords)
                try saveCache(remoteWords)
                return catalog
            } catch {
                // A network or content problem should never prevent the bundled app from working.
            }
        }

        guard let cachedWords = try? loadCache() else { return nil }
        return try? validatedCatalog(from: cachedWords)
    }

    private func fetchAllWords(using configuration: SupabaseConfiguration) async throws -> [WordEntry] {
        var allWords: [WordEntry] = []
        var lowerBound = 0

        while true {
            let upperBound = lowerBound + Self.pageSize - 1
            var request = try makeRequest(
                configuration: configuration,
                lowerBound: lowerBound,
                upperBound: upperBound
            )
            request.timeoutInterval = 15

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CatalogError.invalidResponse
            }

            let page = try JSONDecoder().decode([RemoteWord].self, from: data)
            allWords.append(contentsOf: page.map(\.wordEntry))

            guard page.count == Self.pageSize else { break }
            lowerBound += Self.pageSize
        }

        return allWords
    }

    private func makeRequest(
        configuration: SupabaseConfiguration,
        lowerBound: Int,
        upperBound: Int
    ) throws -> URLRequest {
        let endpoint = configuration.projectURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent("words")

        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw CatalogError.invalidConfiguration
        }

        components.queryItems = [
            URLQueryItem(
                name: "select",
                value: "id,word,pronunciation,part_of_speech,definition,example,difficulty"
            ),
            URLQueryItem(name: "is_active", value: "eq.true"),
            URLQueryItem(name: "published_at", value: "lte.now()"),
            URLQueryItem(name: "order", value: "difficulty.asc,sort_order.asc,id.asc")
        ]

        guard let url = components.url else { throw CatalogError.invalidConfiguration }

        var request = URLRequest(url: url)
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(configuration.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("items", forHTTPHeaderField: "Range-Unit")
        request.setValue("\(lowerBound)-\(upperBound)", forHTTPHeaderField: "Range")
        return request
    }

    private func validatedCatalog(from words: [WordEntry]) throws -> [Difficulty: [WordEntry]] {
        guard Set(words.map(\.id)).count == words.count else {
            throw CatalogError.duplicateIdentifier
        }

        guard words.allSatisfy({ word in
            !word.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !word.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !word.pronunciation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !word.partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !word.definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !word.example.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else {
            throw CatalogError.invalidContent
        }

        let catalog = Dictionary(grouping: words, by: \.difficulty)
        guard Difficulty.allCases.allSatisfy({
            (catalog[$0]?.count ?? 0) >= Self.minimumWordsPerDifficulty
        }) else {
            throw CatalogError.incompleteCatalog
        }

        return catalog
    }

    private func cacheURL() throws -> URL {
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = applicationSupport.appendingPathComponent("EightWords", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableDirectory = directory
        try? mutableDirectory.setResourceValues(values)

        return directory.appendingPathComponent(Self.cacheFileName)
    }

    private func saveCache(_ words: [WordEntry]) throws {
        let data = try JSONEncoder().encode(words)
        try data.write(to: cacheURL(), options: .atomic)
    }

    private func loadCache() throws -> [WordEntry] {
        let data = try Data(contentsOf: cacheURL())
        return try JSONDecoder().decode([WordEntry].self, from: data)
    }

    private enum CatalogError: Error {
        case duplicateIdentifier
        case incompleteCatalog
        case invalidConfiguration
        case invalidContent
        case invalidResponse
    }
}

private struct RemoteWord: Decodable {
    let id: String
    let word: String
    let pronunciation: String
    let partOfSpeech: String
    let definition: String
    let example: String
    let difficulty: Difficulty

    var wordEntry: WordEntry {
        WordEntry(
            id: id,
            word: word,
            pronunciation: pronunciation,
            partOfSpeech: partOfSpeech,
            definition: definition,
            example: example,
            difficulty: difficulty
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case word
        case pronunciation
        case partOfSpeech = "part_of_speech"
        case definition
        case example
        case difficulty
    }
}
