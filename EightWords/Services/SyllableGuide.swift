import Foundation

enum SyllableGuide {
    private static let exceptions: [String: [String]] = [
        "business": ["busi", "ness"],
        "camera": ["cam", "er", "a"],
        "chocolate": ["choc", "o", "late"],
        "comfortable": ["com", "fort", "a", "ble"],
        "different": ["dif", "fer", "ent"],
        "every": ["ev", "er", "y"],
        "family": ["fam", "i", "ly"],
        "favorite": ["fa", "vor", "ite"],
        "fire": ["fire"],
        "flower": ["flow", "er"],
        "hour": ["hour"],
        "interesting": ["in", "ter", "est", "ing"],
        "orange": ["or", "ange"],
        "people": ["peo", "ple"],
        "quiet": ["qui", "et"],
        "science": ["sci", "ence"],
        "several": ["sev", "er", "al"],
        "special": ["spe", "cial"],
        "vegetable": ["veg", "e", "ta", "ble"],
        "wednesday": ["wednes", "day"],
        "wonder": ["won", "der"]
    ]

    static func split(_ input: String) -> [String] {
        let word = String(input.lowercased().filter { $0.isLetter })
        guard !word.isEmpty else { return [] }
        if let exception = exceptions[word] { return exception }

        let letters = Array(word)
        guard letters.count > 3 else { return [word] }

        let vowels = Set<Character>("aeiouy")
        let diphthongs: Set<String> = [
            "ai", "ay", "au", "aw", "ea", "ee", "ei", "ey", "eu", "ie",
            "oa", "oe", "oi", "oo", "ou", "ow", "ue", "ui"
        ]
        var nuclei: [(start: Int, end: Int)] = []
        var index = 0

        while index < letters.count {
            let followsQ = letters[index] == "u" && index > 0 && letters[index - 1] == "q"
            guard vowels.contains(letters[index]), !followsQ else {
                index += 1
                continue
            }

            let start = index
            index += 1
            while index < letters.count, vowels.contains(letters[index]) {
                let pair = String([letters[index - 1], letters[index]])
                if pair == "io", index + 1 < letters.count, letters[index + 1] == "n" {
                    index += 1
                } else if diphthongs.contains(pair) {
                    index += 1
                } else {
                    break
                }
            }
            nuclei.append((start, index - 1))
        }

        let hasSyllabicLE = letters.count >= 3
            && letters[letters.count - 2] == "l"
            && letters[letters.count - 1] == "e"
            && !vowels.contains(letters[letters.count - 3])

        if nuclei.count > 1,
           nuclei.last?.start == letters.count - 1,
           letters.last == "e",
           !hasSyllabicLE {
            nuclei.removeLast()
        }

        guard nuclei.count > 1 else { return [word] }

        let onsetPairs: Set<String> = [
            "bl", "br", "ch", "cl", "cr", "dr", "fl", "fr", "gl", "gr", "ph",
            "pl", "pr", "qu", "sh", "sl", "th", "tr", "tw", "wh", "wr"
        ]
        var boundaries: [Int] = []

        for position in 0..<(nuclei.count - 1) {
            let previous = nuclei[position]
            let next = nuclei[position + 1]
            let clusterStart = previous.end + 1
            let clusterEnd = next.start
            let clusterLength = clusterEnd - clusterStart
            let boundary: Int

            if hasSyllabicLE, position == nuclei.count - 2 {
                boundary = max(clusterStart, letters.count - 3)
            } else if clusterLength <= 1 {
                boundary = clusterStart
            } else {
                let finalPair = String([letters[clusterEnd - 2], letters[clusterEnd - 1]])
                boundary = onsetPairs.contains(finalPair) ? clusterEnd - 2 : clusterEnd - 1
            }
            boundaries.append(max(1, boundary))
        }

        var pieces: [String] = []
        var start = 0
        for boundary in Array(Set(boundaries)).sorted() where boundary > start {
            pieces.append(String(letters[start..<boundary]))
            start = boundary
        }
        if start < letters.count {
            pieces.append(String(letters[start..<letters.count]))
        }
        return pieces.filter { !$0.isEmpty }
    }
}
