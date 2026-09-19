import Foundation

enum WordLibrary {
    static let entries: [Difficulty: [WordEntry]] = [
        .beginner: [
            word("brisk", "brisk", "adjective", "Quick, lively, and full of energy.", "We took a brisk walk before breakfast.", .beginner),
            word("cozy", "KOH-zee", "adjective", "Warm, comfortable, and relaxing.", "The reading corner felt cozy on the rainy day.", .beginner),
            word("dazzle", "DAZ-uhl", "verb", "To impress someone with brightness or skill.", "The dancer's quick steps dazzled the crowd.", .beginner),
            word("eager", "EE-ger", "adjective", "Excited and ready to do something.", "Maya was eager to open her new book.", .beginner),
            word("flutter", "FLUT-er", "verb", "To move with quick, light motions.", "The little flag began to flutter in the breeze.", .beginner),
            word("glimpse", "glimps", "noun", "A quick or partial look.", "We caught a glimpse of the deer in the woods.", .beginner),
            word("harmony", "HAR-muh-nee", "noun", "A pleasing way that sounds or people work together.", "Their voices blended in harmony.", .beginner),
            word("invent", "in-VENT", "verb", "To create something that did not exist before.", "They worked together to invent a new game.", .beginner),
            word("jolly", "JOL-ee", "adjective", "Happy, cheerful, and friendly.", "Our jolly neighbor waved from across the street.", .beginner),
            word("keen", "keen", "adjective", "Very interested, eager, or sharp.", "Noah has a keen eye for small details.", .beginner),
            word("linger", "LING-ger", "verb", "To stay somewhere a little longer.", "The smell of cinnamon seemed to linger.", .beginner),
            word("mend", "mend", "verb", "To repair something that is damaged.", "I used a patch to mend the tiny tear.", .beginner),
            word("nifty", "NIF-tee", "adjective", "Especially good, clever, or useful.", "That folding stool is a nifty idea.", .beginner),
            word("observe", "ub-ZURV", "verb", "To watch or notice something carefully.", "We sat quietly to observe the birds.", .beginner),
            word("peculiar", "pih-KYOOL-yur", "adjective", "Unusual or a little strange.", "A peculiar sound came from the old clock.", .beginner),
            word("radiant", "RAY-dee-unt", "adjective", "Shining brightly or showing great happiness.", "Her radiant smile welcomed everyone.", .beginner),
            word("sturdy", "STUR-dee", "adjective", "Strong and not easily damaged.", "The sturdy bridge held up through the storm.", .beginner),
            word("tranquil", "TRANG-kwil", "adjective", "Quiet, calm, and peaceful.", "The garden was tranquil just after sunrise.", .beginner),
            word("venture", "VEN-chur", "noun", "A new activity that may be exciting or risky.", "The bake sale was their first business venture.", .beginner),
            word("whimsical", "WIM-zih-kul", "adjective", "Playfully unusual or imaginative.", "The artist filled the wall with whimsical animals.", .beginner)
        ],
        .intermediate: [
            word("adapt", "uh-DAPT", "verb", "To change in order to fit a new situation.", "Plants adapt to the amount of light they receive.", .intermediate),
            word("benevolent", "buh-NEV-uh-lunt", "adjective", "Kind and generous toward others.", "A benevolent donor supplied books for the library.", .intermediate),
            word("candid", "KAN-did", "adjective", "Honest and direct, even when the truth is difficult.", "She gave a candid answer about the project.", .intermediate),
            word("diligent", "DIL-ih-junt", "adjective", "Careful and persistent in your work.", "His diligent practice made the song sound effortless.", .intermediate),
            word("eloquent", "EL-uh-kwunt", "adjective", "Fluent, clear, and persuasive in expression.", "Her eloquent speech moved the audience.", .intermediate),
            word("frugal", "FROO-gul", "adjective", "Careful about spending money or using resources.", "Packing lunch is a frugal habit.", .intermediate),
            word("gratify", "GRAT-uh-fy", "verb", "To give pleasure or satisfaction.", "It gratified him to see the garden thrive.", .intermediate),
            word("hypothesis", "hy-POTH-uh-sis", "noun", "An idea that can be tested to see if it is true.", "Our hypothesis predicted which seed would sprout first.", .intermediate),
            word("impartial", "im-PAR-shul", "adjective", "Fair and not favoring one side.", "The judge remained impartial during the debate.", .intermediate),
            word("jovial", "JOH-vee-ul", "adjective", "Friendly, cheerful, and good-humored.", "His jovial greeting put everyone at ease.", .intermediate),
            word("kinetic", "kih-NET-ik", "adjective", "Related to motion or produced by movement.", "The sculpture turns wind into kinetic energy.", .intermediate),
            word("lucid", "LOO-sid", "adjective", "Expressed clearly and easy to understand.", "The guide gave a lucid explanation of the rules.", .intermediate),
            word("meticulous", "muh-TIK-yuh-lus", "adjective", "Very careful about small details.", "She kept meticulous notes during the experiment.", .intermediate),
            word("novel", "NOV-uhl", "adjective", "New, original, or unusual.", "The team found a novel solution to the problem.", .intermediate),
            word("optimistic", "op-tuh-MIS-tik", "adjective", "Expecting good things to happen.", "Despite the delay, the hikers stayed optimistic.", .intermediate),
            word("pragmatic", "prag-MAT-ik", "adjective", "Focused on practical results.", "We chose the most pragmatic plan for the time available.", .intermediate),
            word("resilient", "rih-ZIL-yunt", "adjective", "Able to recover quickly after difficulty.", "The resilient little tree grew after the fire.", .intermediate),
            word("scrutinize", "SKROOT-n-eyes", "verb", "To examine something very carefully.", "The editor will scrutinize every sentence.", .intermediate),
            word("tangible", "TAN-juh-bul", "adjective", "Real, clear, or able to be touched.", "Finishing the first chapter was tangible progress.", .intermediate),
            word("versatile", "VUR-suh-tyl", "adjective", "Able to do many different things well.", "A plain notebook is a versatile tool.", .intermediate)
        ],
        .advanced: [
            word("ameliorate", "uh-MEEL-yuh-rayt", "verb", "To make an unpleasant situation better.", "New shade trees may ameliorate the summer heat.", .advanced),
            word("bucolic", "byoo-KOL-ik", "adjective", "Relating to the pleasant aspects of the countryside.", "The painting shows a bucolic scene of fields and sheep.", .advanced),
            word("circumspect", "SUR-kum-spekt", "adjective", "Careful to consider possible risks before acting.", "The board was circumspect about making a quick decision.", .advanced),
            word("deleterious", "del-uh-TEER-ee-us", "adjective", "Causing harm or damage.", "Too little sleep can have a deleterious effect on focus.", .advanced),
            word("ephemeral", "ih-FEM-er-ul", "adjective", "Lasting for only a short time.", "The artist created an ephemeral pattern in the sand.", .advanced),
            word("fastidious", "fa-STID-ee-us", "adjective", "Very attentive to accuracy and detail.", "The fastidious baker measured every ingredient twice.", .advanced),
            word("gregarious", "grih-GAIR-ee-us", "adjective", "Sociable and fond of company.", "Her gregarious nature made newcomers feel welcome.", .advanced),
            word("heuristic", "hyoo-RIS-tik", "noun", "A practical shortcut used to solve a problem or learn something.", "The rule of thumb was a useful heuristic.", .advanced),
            word("ineffable", "in-EF-uh-bul", "adjective", "Too great or unusual to be expressed in words.", "They watched the eclipse with ineffable wonder.", .advanced),
            word("juxtapose", "JUK-stuh-pohz", "verb", "To place things together to highlight their differences.", "The exhibit will juxtapose ancient tools with modern ones.", .advanced),
            word("laconic", "luh-KON-ik", "adjective", "Using very few words.", "His laconic reply left no room for debate.", .advanced),
            word("mellifluous", "muh-LIF-loo-us", "adjective", "Pleasantly smooth and musical to hear.", "The narrator's mellifluous voice suited the bedtime story.", .advanced),
            word("nuance", "NOO-ahns", "noun", "A subtle difference in meaning, feeling, or appearance.", "The actor captured every nuance of the character.", .advanced),
            word("obfuscate", "OB-fuh-skayt", "verb", "To make something unclear or difficult to understand.", "Extra jargon can obfuscate a simple idea.", .advanced),
            word("perspicacious", "pur-spih-KAY-shus", "adjective", "Quick to notice and understand difficult things.", "Her perspicacious questions revealed the plan's weakness.", .advanced),
            word("quixotic", "kwik-SOT-ik", "adjective", "Extremely idealistic but not very practical.", "His quixotic plan involved sailing around the world in a month.", .advanced),
            word("reticent", "RET-ih-sunt", "adjective", "Not revealing thoughts or feelings readily.", "She was reticent at first, then shared her idea.", .advanced),
            word("sagacious", "suh-GAY-shus", "adjective", "Showing wise judgment and good sense.", "The sagacious mentor encouraged patience.", .advanced),
            word("ubiquitous", "yoo-BIK-wih-tus", "adjective", "Present or found nearly everywhere.", "Smartphones have become ubiquitous in many cities.", .advanced),
            word("verisimilitude", "ver-uh-sih-MIL-ih-tood", "noun", "The appearance of being true or real.", "Small historical details gave the story verisimilitude.", .advanced)
        ]
    ]

    static func words(
        for difficulty: Difficulty,
        on date: Date = .now,
        entries catalog: [Difficulty: [WordEntry]] = entries
    ) -> [WordEntry] {
        guard let source = catalog[difficulty], !source.isEmpty else { return [] }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        let levelOffset = Difficulty.allCases.firstIndex(of: difficulty) ?? 0
        let start = (day * 7 + levelOffset * 5) % source.count

        return (0..<source.count).map { source[(start + $0) % source.count] }
    }

    private static func word(
        _ word: String,
        _ pronunciation: String,
        _ partOfSpeech: String,
        _ definition: String,
        _ example: String,
        _ difficulty: Difficulty
    ) -> WordEntry {
        WordEntry(
            word: word,
            pronunciation: pronunciation,
            partOfSpeech: partOfSpeech,
            definition: definition,
            example: example,
            difficulty: difficulty
        )
    }
}
