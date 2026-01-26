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
        NSLog("SceneDelegate: scene willConnectTo called")
        guard let windowScene = scene as? UIWindowScene else {
            NSLog("SceneDelegate: Failed to get windowScene")
            return
        }
        window = UIWindow(windowScene: windowScene)
        NSLog("SceneDelegate: isConfigured = \(configStore.isConfigured)")

        if configStore.isConfigured {
            NSLog("SceneDelegate: Showing EditorViewController")
            window?.rootViewController = Bootstrap.createEditorViewController()
        } else {
            NSLog("SceneDelegate: Showing SettingsViewController")
            window?.rootViewController = Bootstrap.createSettingsViewController { [weak self] in
                self?.transitionToEditor()
            }
        }

        window?.makeKeyAndVisible()
        NSLog("SceneDelegate: Window made key and visible")

        // Start sync after window is visible, on background thread
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
        window?.rootViewController = Bootstrap.createEditorViewController()
        startSyncAsync()
    }
}
