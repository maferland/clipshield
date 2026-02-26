import Testing
@testable import ClipShield

private let allPatterns: Set<PatternType> = Set(PatternType.allCases)

@Suite("luhn")
struct LuhnTests {
    @Test("validates digits", arguments: [
        ("4111111111111111", true),
        ("4111111111111112", false),
        ("5500000000000004", true),
        ("378282246310005", true),
        ("0000000000000000", true),
        ("1234567890123456", false),
    ])
    func validate(digits: String, expected: Bool) {
        #expect(luhn(digits) == expected)
    }
}

@Suite("detect")
struct DetectTests {
    @Suite("credit cards")
    struct CreditCards {
        @Test("detects card", arguments: [
            ("4111111111111111", "plain Visa"),
            ("4111 1111 1111 1111", "spaced Visa"),
            ("4111-1111-1111-1111", "dashed Visa"),
            ("5500000000000004", "Mastercard"),
            ("378282246310005", "Amex"),
        ])
        func detectsCard(input: String, label: String) {
            let results = detect(input, enabled: allPatterns)
            #expect(results.count == 1)
            #expect(results[0].type == .cc)
        }

        @Test("rejects invalid Luhn")
        func rejectsInvalidLuhn() {
            #expect(detect("4111111111111112", enabled: allPatterns).isEmpty)
        }

        @Test("rejects short numbers")
        func rejectsShort() {
            #expect(detect("411111111111", enabled: allPatterns).isEmpty)
        }
    }

    @Suite("SSN (US)")
    struct SSN {
        @Test("detects valid SSN format")
        func detectsSSN() {
            let results = detect("123-45-6789", enabled: allPatterns)
            #expect(results.count == 1)
            #expect(results[0].type == .ssn)
        }

        @Test("ignores SSN without dashes")
        func ignoresNoDashes() {
            #expect(detect("123456789", enabled: [.ssn]).isEmpty)
        }
    }

    @Suite("SIN (CA)")
    struct SIN {
        @Test("detects SIN", arguments: [
            ("123 456 789", "spaced"),
            ("123-456-789", "dashed"),
        ])
        func detectsSIN(input: String, label: String) {
            let results = detect(input, enabled: allPatterns)
            #expect(results.contains { $0.type == .sin })
        }
    }

    @Suite("pattern filtering")
    struct Filtering {
        @Test("respects enabled patterns")
        func respectsEnabled() {
            #expect(detect("123-45-6789", enabled: [.cc]).isEmpty)
        }

        @Test("returns empty for no enabled patterns")
        func emptyPatterns() {
            #expect(detect("4111111111111111", enabled: []).isEmpty)
        }
    }

    @Suite("mixed content")
    struct Mixed {
        @Test("detects sensitive data embedded in text")
        func detectsMixed() {
            let text = "My card is 4111 1111 1111 1111 and SSN is 123-45-6789"
            let results = detect(text, enabled: allPatterns)
            #expect(results.count >= 2)
        }

        @Test("ignores clean text")
        func ignoresClean() {
            #expect(detect("Hello world, nothing sensitive here!", enabled: allPatterns).isEmpty)
        }
    }
}
