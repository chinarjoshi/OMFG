import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let syncEngine = SyncEngine.shared
    private let configStore = ConfigStore.shared

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)

        if configStore.isConfigured {
            window?.rootViewController = createEditorViewController()
        } else {
            window?.rootViewController = SettingsViewController { [weak self] in
                self?.transitionToEditor()
            }
        }

        window?.makeKeyAndVisible()

        if configStore.isConfigured {
            startSyncAsync()
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        startSyncAsync()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        syncEngine.beginBackgroundSync()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.syncEngine.endBackgroundSync()
        }
    }

    private func startSyncAsync() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self, !self.syncEngine.isRunning else { return }
            self.syncEngine.start()
        }
    }

    private func transitionToEditor() {
        window?.rootViewController = createEditorViewController()
        startSyncAsync()
    }

    private func createEditorViewController() -> EditorViewController {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dailyNoteManager = DailyNoteManager(baseDirectory: documentsURL)
        return EditorViewController(
            dailyNoteManager: dailyNoteManager,
            autoSaveController: AutoSaveController(),
            fileWatcher: FileWatcher()
        )
    }
}
