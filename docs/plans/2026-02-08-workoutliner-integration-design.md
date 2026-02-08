# WorkoutLiner Integration Design

## Summary

Embed the WorkoutLiner Swift library into OMFG to automatically transform natural workout notation into formatted org-mode tables when the cursor leaves a paragraph.

## Trigger

When cursor leaves a paragraph:
1. Check if paragraph contains any numbers (heuristic)
2. Skip if paragraph is already a table (starts with `|`)
3. Run WorkoutLiner parser
4. If parser returns a table, replace paragraph; otherwise leave unchanged

## Example

Input:
```
squat 8 8 8 135
bench 3x8 95
```

Output:
```
| Exercise | 1     | 2     | 3     |
|----------|-------|-------|-------|
| Squat    | 8@135 | 8@135 | 8@135 |
| Bench    | 8@95  | 8@95  | 8@95  |
```

## Dependency

Add WorkoutLiner as local Swift Package:
- Path: `~/workoutliner/.worktrees/antlr-parser/swift`
- Brings in ANTLR4 runtime (~2MB)

## Files

| File | Changes |
|------|---------|
| `omfg.xcodeproj` | Add WorkoutLiner package dependency |
| `OMFG/WorkoutTransformer.swift` | New file with paragraph tracking and transform logic |
| `OMFG/Editor.swift` | Call WorkoutTransformer from textViewDidChangeSelection |

## Implementation

### WorkoutTransformer.swift (new file)

```swift
import Foundation
import WorkoutLiner

final class WorkoutTransformer {
    private weak var textStorage: NSTextStorage?
    private var previousParagraphRange: NSRange?

    init(textStorage: NSTextStorage) {
        self.textStorage = textStorage
    }

    func selectionChanged(to position: Int) {
        guard let textStorage = textStorage else { return }
        let text = textStorage.string as NSString

        let currentParagraph = paragraphRange(in: text, at: position)

        if let prevRange = previousParagraphRange,
           currentParagraph?.location != prevRange.location {
            transformIfNeeded(in: prevRange, text: text)
        }

        previousParagraphRange = currentParagraph
    }

    private func paragraphRange(in text: NSString, at position: Int) -> NSRange? {
        guard position <= text.length else { return nil }
        return text.paragraphRange(for: NSRange(location: position, length: 0))
    }

    private func transformIfNeeded(in range: NSRange, text: NSString) {
        let paragraph = text.substring(with: range)

        // Heuristic: skip if no numbers
        guard paragraph.contains(where: { $0.isNumber }) else { return }

        // Skip if already a table
        guard !paragraph.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("|") else { return }

        let transformed = WorkoutLiner.transform(paragraph)

        // Only replace if transformation produced a table
        if transformed != paragraph && transformed.contains("|") {
            textStorage?.replaceCharacters(in: range, with: transformed + "\n")
        }
    }
}
```

### Editor.swift changes

```swift
// Add property
private var workoutTransformer: WorkoutTransformer?

// In init or viewDidLoad
workoutTransformer = WorkoutTransformer(textStorage: textStorage)

// In textViewDidChangeSelection
workoutTransformer?.selectionChanged(to: textView.selectedRange.location)
```

## Interaction with Table Formatting

No conflict:
- WorkoutTransformer skips paragraphs starting with `|`
- Table formatter only acts on lines matching `^|.+|$`

Workflow:
1. Type workout notation → tap away → WorkoutLiner creates table
2. Edit table cell → tap away → table formatter aligns columns
