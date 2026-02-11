// Run: swift MergeTests.swift
import Foundation

// --- Implementation (must match Editor.swift) ---

func lcs(_ a: [String], _ b: [String]) -> [(Int, Int)] {
    let m = a.count, n = b.count
    guard m > 0 && n > 0 else { return [] }
    var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
    for i in 1...m {
        for j in 1...n {
            dp[i][j] = a[i-1] == b[j-1] ? dp[i-1][j-1] + 1 : max(dp[i-1][j], dp[i][j-1])
        }
    }
    var result: [(Int, Int)] = []
    var i = m, j = n
    while i > 0 && j > 0 {
        if a[i-1] == b[j-1] {
            result.append((i-1, j-1))
            i -= 1; j -= 1
        } else if dp[i-1][j] >= dp[i][j-1] {
            i -= 1
        } else {
            j -= 1
        }
    }
    return result.reversed()
}

func mergeTwo(_ a: String, _ b: String) -> String {
    let aLines = a.components(separatedBy: "\n")
    let bLines = b.components(separatedBy: "\n")
    let matches = lcs(aLines, bLines)

    var result: [String] = []
    var ai = 0, bi = 0
    for (mi, ni) in matches {
        result += aLines[ai..<mi]
        result += bLines[bi..<ni]
        result.append(aLines[mi])
        ai = mi + 1
        bi = ni + 1
    }
    result += aLines[ai...]
    result += bLines[bi...]
    return result.joined(separator: "\n")
}

// --- Tests ---

func testBothAppend() {
    let a = "line1\nline2\nA\n"
    let b = "line1\nline2\nB\n"
    let result = mergeTwo(a, b)
    assert(result == "line1\nline2\nA\nB\n",
           "Both append: Got:\n\(result)")
}

func testBothAppendMultiple() {
    let a = "x\nA1\nA2\n"
    let b = "x\nB1\nB2\n"
    let result = mergeTwo(a, b)
    assert(result == "x\nA1\nA2\nB1\nB2\n",
           "Both append multiple: Got:\n\(result)")
}

func testIdentical() {
    let a = "same\ncontent\n"
    assert(mergeTwo(a, a) == a, "Identical inputs should be unchanged")
}

func testOneSideUnchanged() {
    let base = "line1\nline2\n"
    let edited = "line1\nline2\nnew\n"
    assert(mergeTwo(edited, base) == edited, "Edited + base should keep edits")
    assert(mergeTwo(base, edited) == edited, "Base + edited should keep edits")
}

func testEditDifferentSections() {
    let a = "HEADER\nbody\nfooter\n"
    let b = "header\nbody\nFOOTER\n"
    let result = mergeTwo(a, b)
    assert(result.contains("HEADER"), "a's edit missing. Got:\n\(result)")
    assert(result.contains("FOOTER"), "b's edit missing. Got:\n\(result)")
    let bodyCount = result.components(separatedBy: "\n").filter { $0 == "body" }.count
    assert(bodyCount == 1, "Shared line 'body' duplicated. Got:\n\(result)")
}

func testInsertAtDifferentPositions() {
    let a = "top\nmiddle\n"
    let b = "middle\nbottom\n"
    let result = mergeTwo(a, b)
    assert(result == "top\nmiddle\nbottom\n",
           "Insert at different positions: Got:\n\(result)")
}

func testOneSideEmpty() {
    let a = "content\n"
    assert(mergeTwo(a, "").contains("content"), "Non-empty side preserved")
    assert(mergeTwo("", a).contains("content"), "Non-empty side preserved (reversed)")
}

func testTrailingNewline() {
    let a = "line1\nA\n"
    let b = "line1\nB\n"
    assert(mergeTwo(a, b).hasSuffix("\n"), "Trailing newline preserved")
}

func testConflictFilePattern() {
    let pattern = try! NSRegularExpression(pattern: "\\.sync-conflict-\\d{8}-\\d{6}-[A-Z0-9]{7}(?=\\.)")

    for name in [
        "2026-02-11.sync-conflict-20260211-103045-ABCDEFG.org",
        "notes.sync-conflict-20260101-000000-AAAAAAA.org",
    ] {
        let range = NSRange(name.startIndex..., in: name)
        assert(pattern.firstMatch(in: name, range: range) != nil, "Should match: \(name)")
    }

    for name in ["2026-02-11.org", "notes.txt", "sync-conflict-file.org"] {
        let range = NSRange(name.startIndex..., in: name)
        assert(pattern.firstMatch(in: name, range: range) == nil, "Should NOT match: \(name)")
    }
}

func testConflictFileMerge() {
    let winner = "line1\nline2\nremote-added\n"
    let loser  = "line1\nline2\nlocal-added\n"
    let merged = mergeTwo(winner, loser)

    assert(merged.contains("remote-added"), "Winner content lost")
    assert(merged.contains("local-added"), "Loser content lost")

    let lines = merged.components(separatedBy: "\n").filter { !$0.isEmpty }
    assert(lines.count == Set(lines).count, "Duplication in merge")
}

func testNoDuplicationNoLoss() {
    let a = [
        "* Morning", "coffee", "journal",
        "* Workout", "squat 135 145", "bench 95",
        "* Evening", "read", ""
    ].joined(separator: "\n")

    let b = [
        "* Morning", "coffee",
        "* Workout", "squat 135", "bench 95", "deadlift 225",
        "* Evening", "read", "walk", ""
    ].joined(separator: "\n")

    let result = mergeTwo(a, b)
    let resultLines = result.components(separatedBy: "\n")

    for line in ["* Morning", "coffee", "journal", "squat 135 145",
                 "bench 95", "deadlift 225", "* Workout", "* Evening",
                 "read", "walk"] {
        assert(resultLines.contains(line), "NO LOSS: '\(line)' missing.\nGot:\n\(result)")
    }

    var seen: [String: Int] = [:]
    for line in resultLines where !line.isEmpty { seen[line, default: 0] += 1 }
    for (line, count) in seen {
        assert(count == 1, "DUPLICATION: '\(line)' appears \(count) times.\nGot:\n\(result)")
    }
}

// --- Run ---

let tests: [(String, () -> Void)] = [
    ("testBothAppend", testBothAppend),
    ("testBothAppendMultiple", testBothAppendMultiple),
    ("testIdentical", testIdentical),
    ("testOneSideUnchanged", testOneSideUnchanged),
    ("testEditDifferentSections", testEditDifferentSections),
    ("testInsertAtDifferentPositions", testInsertAtDifferentPositions),
    ("testOneSideEmpty", testOneSideEmpty),
    ("testTrailingNewline", testTrailingNewline),
    ("testConflictFilePattern", testConflictFilePattern),
    ("testConflictFileMerge", testConflictFileMerge),
    ("testNoDuplicationNoLoss", testNoDuplicationNoLoss),
]

print("Running \(tests.count) tests...")
for (name, test) in tests {
    test()
    print("  ✓ \(name)")
}
print("All tests passed!")
