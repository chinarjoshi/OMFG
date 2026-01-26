import Foundation

enum Bootstrap {
    static func createEditorViewController() -> EditorViewController {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dailyNoteManager = DailyNoteManager(baseDirectory: documentsURL)
        let fileStore = FileStore()
        let autoSaveController = AutoSaveController(fileStore: fileStore)
        let fileWatcher = FileWatcher()

        return EditorViewController(
            dailyNoteManager: dailyNoteManager,
            autoSaveController: autoSaveController,
            fileWatcher: fileWatcher
        )
    }

    static func createSettingsViewController(onComplete: @escaping () -> Void) -> SettingsViewController {
        SettingsViewController(onComplete: onComplete)
    }
}
