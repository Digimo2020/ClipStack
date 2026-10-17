import Foundation

/// Emoji list built from Unicode properties (no bundled data file). Names come from Unicode, e.g. "grinning face".
enum EmojiData {
    struct Entry { let char: String; let name: String }

    static let all: [Entry] = build()

    private static let aliases: [String: String] = [
        "lol": "tears of joy", "haha": "tears of joy", "love": "heart", "like": "thumbs up", "ok": "ok hand",
        "party": "party popper", "cry": "crying", "happy": "smiling", "sad": "disappointed", "laugh": "grinning",
        "thanks": "folded hands", "pray": "folded hands", "please": "folded hands", "cool": "sunglasses",
        "think": "thinking", "yes": "check mark", "no": "cross mark", "money": "money", "celebrate": "party popper",
        "idea": "light bulb", "done": "check mark", "wow": "astonished", "sleep": "sleeping", "angry": "pouting",
    ]

    static func search(_ query: String) -> [String] {
        let q = query.lowercased()
        return all.filter { e in
            e.name.contains(q) || aliases.contains { $0.key.hasPrefix(q) && e.name.contains($0.value) }
        }.map(\.char)
    }

    static func name(of char: String) -> String {
        all.first(where: { $0.char == char })?.name.capitalized ?? ""
    }

    private static func build() -> [Entry] {
        // Ordered roughly like the system picker: faces, people, hearts, animals, food, activities, travel, objects, symbols.
        let ranges: [ClosedRange<UInt32>] = [
            0x1F600...0x1F64F, 0x1F910...0x1F92F, 0x1F970...0x1F97F, 0x1FAE0...0x1FAEF,
            0x1F440...0x1F450, 0x1F466...0x1F487, 0x1F9D0...0x1F9FF, 0x1F4AA...0x1F4AA,
            0x2764...0x2764, 0x1F493...0x1F49F, 0x1F90D...0x1F90E, 0x1F5A4...0x1F5A4,
            0x1F400...0x1F43F, 0x1F980...0x1F9AE, 0x1F330...0x1F344,
            0x1F345...0x1F37F, 0x1F950...0x1F96F,
            0x1F380...0x1F3FA, 0x26BD...0x26BE, 0x1F3C0...0x1F3CF,
            0x1F680...0x1F6C5, 0x1F30D...0x1F320, 0x1F321...0x1F32C,
            0x1F4A1...0x1F4FF, 0x1F500...0x1F53D, 0x1F4A5...0x1F4A9,
            0x2600...0x26FF, 0x2705...0x2705, 0x274C...0x274C, 0x2728...0x2728, 0x2B50...0x2B50, 0x2753...0x2757, 0x1F525...0x1F525,
        ]
        var seen = Set<UInt32>()
        var out: [Entry] = []
        for r in ranges {
            for v in r {
                guard !seen.contains(v), let s = Unicode.Scalar(v) else { continue }
                if (0x1F3FB...0x1F3FF).contains(v) { continue }  // skin-tone modifiers
                guard s.properties.isEmoji else { continue }
                seen.insert(v)
                var str = String(Character(s))
                if !s.properties.isEmojiPresentation { str += "\u{FE0F}" }
                out.append(Entry(char: str, name: (s.properties.name ?? "").lowercased()))
            }
        }
        return out
    }
}
