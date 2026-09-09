import Foundation

nonisolated enum BarcodeNormalizer {
    static func normalize(_ raw: String) -> String? {
        let digits = raw.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }

        if digits.count == 13, isValidEAN13(digits) {
            return digits
        }

        if digits.count == 8, isValidEAN8(digits) {
            return digits
        }

        if digits.count == 12 {
            if let ean13 = ean13ByAddingPrefix(to: digits) {
                return ean13
            }
            let upcAsEAN = "0" + digits
            if isValidEAN13(upcAsEAN) {
                return upcAsEAN
            }
        }

        if digits.count > 13 {
            return findValidEAN13(in: digits)
        }

        if digits.count >= 13 {
            return findValidEAN13(in: digits)
        }

        return nil
    }

    static func extractFromTextLines(_ lines: [String]) -> String? {
        let combined = lines.joined(separator: " ")

        if let match = combined.range(
            of: #"\d[\s\-]?\d{6}[\s\-]?\d{5,6}"#,
            options: .regularExpression
        ) {
            if let normalized = normalize(String(combined[match])) {
                return normalized
            }
        }

        let allDigits = combined.filter(\.isNumber)
        if let fromAll = normalize(allDigits) ?? findValidEAN13(in: allDigits) {
            return fromAll
        }

        for line in lines {
            if let normalized = normalize(line) {
                return normalized
            }
        }

        return nil
    }

    private static func ean13ByAddingPrefix(to twelveDigits: String) -> String? {
        for prefix in 0...9 {
            let candidate = "\(prefix)" + twelveDigits
            if isValidEAN13(candidate) {
                return candidate
            }
        }
        return nil
    }

    private static func findValidEAN13(in digits: String) -> String? {
        guard digits.count >= 13 else { return nil }

        var index = digits.startIndex
        while digits.distance(from: index, to: digits.endIndex) >= 13 {
            let end = digits.index(index, offsetBy: 13)
            let candidate = String(digits[index..<end])
            if isValidEAN13(candidate) {
                return candidate
            }
            index = digits.index(after: index)
        }
        return nil
    }

    static func isValidEAN13(_ code: String) -> Bool {
        guard code.count == 13, code.allSatisfy(\.isNumber) else { return false }
        let values = code.compactMap { Int(String($0)) }
        guard values.count == 13 else { return false }

        let sum = values[0..<12].enumerated().reduce(0) { total, pair in
            total + pair.element * (pair.offset.isMultiple(of: 2) ? 1 : 3)
        }
        let check = (10 - (sum % 10)) % 10
        return check == values[12]
    }

    private static func isValidEAN8(_ code: String) -> Bool {
        guard code.count == 8, code.allSatisfy(\.isNumber) else { return false }
        let values = code.compactMap { Int(String($0)) }
        guard values.count == 8 else { return false }

        let sum = values[0..<7].enumerated().reduce(0) { total, pair in
            total + pair.element * (pair.offset.isMultiple(of: 2) ? 3 : 1)
        }
        let check = (10 - (sum % 10)) % 10
        return check == values[7]
    }
}
