import UIKit

struct SyntaxRule {
    let pattern: NSRegularExpression
    let attributes: [NSAttributedString.Key: Any]
}

struct OrgSyntaxRules {
    let all: [SyntaxRule]

    init() {
        all = [
            // Headers
            Self.rule("^\\* .+$", .anchorsMatchLines, color: .white, font: .monospacedSystemFont(ofSize: 24, weight: .bold)),
            Self.rule("^\\*\\* .+$", .anchorsMatchLines, color: .white, font: .monospacedSystemFont(ofSize: 20, weight: .bold)),
            Self.rule("^\\*\\*\\* .+$", .anchorsMatchLines, color: .white, font: .monospacedSystemFont(ofSize: 18, weight: .semibold)),
            // Keywords
            Self.rule("\\bTODO\\b", color: .systemRed, font: .monospacedSystemFont(ofSize: 16, weight: .bold)),
            Self.rule("\\bDONE\\b", color: .systemGreen, font: .monospacedSystemFont(ofSize: 16, weight: .bold)),
            // Links
            Self.rule("\\[\\[[^\\]]+\\]\\]", color: .systemBlue, underline: true),
            // Formatting
            Self.rule("(?<=\\s|^)\\*[^\\*\\n]+\\*(?=\\s|$)", .anchorsMatchLines, font: .monospacedSystemFont(ofSize: 16, weight: .bold)),
            Self.rule("(?<=\\s|^)/[^/\\n]+/(?=\\s|$)", .anchorsMatchLines, font: .italicSystemFont(ofSize: 16)),
            // Timestamps
            Self.rule("<[^>]+>", color: .systemPurple, background: UIColor.systemPurple.withAlphaComponent(0.1)),
        ]
    }

    private static func rule(
        _ pattern: String,
        _ options: NSRegularExpression.Options = [],
        color: UIColor? = nil,
        font: UIFont? = nil,
        underline: Bool = false,
        background: UIColor? = nil
    ) -> SyntaxRule {
        var attrs: [NSAttributedString.Key: Any] = [:]
        if let color = color { attrs[.foregroundColor] = color }
        if let font = font { attrs[.font] = font }
        if underline { attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue }
        if let background = background { attrs[.backgroundColor] = background }
        return SyntaxRule(
            pattern: try! NSRegularExpression(pattern: pattern, options: options),
            attributes: attrs
        )
    }
}
