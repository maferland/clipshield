import Foundation

enum PatternType: String, CaseIterable {
    case cc, ssn, sin

    var label: String {
        switch self {
        case .cc: return "Credit Card"
        case .ssn: return "SSN (US)"
        case .sin: return "SIN (CA)"
        }
    }
}

struct Detection {
    let type: PatternType
    let label: String
    let match: String
}

func luhn(_ digits: String) -> Bool {
    let nums = digits.compactMap { $0.wholeNumberValue }
    guard nums.count == digits.count else { return false }
    var sum = 0
    var alternate = false

    for i in stride(from: nums.count - 1, through: 0, by: -1) {
        var n = nums[i]
        if alternate {
            n *= 2
            if n > 9 { n -= 9 }
        }
        sum += n
        alternate.toggle()
    }

    return sum % 10 == 0
}

private struct Pattern {
    let type: PatternType
    let regex: NSRegularExpression
    let validate: ((String) -> Bool)?
}

private let patterns: [Pattern] = {
    func regex(_ pattern: String) -> NSRegularExpression {
        try! NSRegularExpression(pattern: pattern)
    }
    return [
        Pattern(type: .cc, regex: regex(#"\b(?:\d[ -]*?){13,19}\b"#)) { match in
            let digits = match.filter(\.isNumber)
            return digits.count >= 13 && digits.count <= 19 && luhn(digits)
        },
        Pattern(type: .ssn, regex: regex(#"\b\d{3}-\d{2}-\d{4}\b"#), validate: nil),
        Pattern(type: .sin, regex: regex(#"\b\d{3}[ -]\d{3}[ -]\d{3}\b"#), validate: nil),
    ]
}()

func detect(_ text: String, enabled: Set<PatternType>) -> [Detection] {
    var results: [Detection] = []
    let range = NSRange(text.startIndex..., in: text)

    for pattern in patterns {
        guard enabled.contains(pattern.type) else { continue }

        let matches = pattern.regex.matches(in: text, range: range)
        for m in matches {
            guard let matchRange = Range(m.range, in: text) else { continue }
            let match = String(text[matchRange])
            if let validate = pattern.validate, !validate(match) { continue }
            results.append(Detection(type: pattern.type, label: pattern.type.label, match: match))
        }
    }

    return results
}
