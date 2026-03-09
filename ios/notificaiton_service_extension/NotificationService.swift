import Flutter
import Foundation
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    var engine: FlutterEngine?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        DispatchQueue.main.async {
            self.startEngine()
        }
    }

    func startEngine() {
        guard let appFrameworkURL = Bundle.main.url(forResource: "App", withExtension: "framework", subdirectory: "Frameworks"),
              let appBundle = Bundle(url: appFrameworkURL) else {
            serviceExtensionTimeWillExpire()
            return
        }
        let project = FlutterDartProject(precompiledDartBundle: appBundle)
        let flutterEngine = FlutterEngine(name: "nse", project: project, allowHeadlessExecution: true)
        engine = flutterEngine
        flutterEngine.run(withEntrypoint: "notificationServiceExtension", libraryURI: nil, initialRoute: nil, entrypointArgs: nil)
        GeneratedPluginRegistrant.register(with: flutterEngine)
        let channel = FlutterMethodChannel(name: "com.example.nse/channel", binaryMessenger: flutterEngine.binaryMessenger)
        channel.setMethodCallHandler { [weak self] (call, result) in
            if call.method == "done" {
                result(nil)
                self?.serviceExtensionTimeWillExpire()
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
        engine?.destroyContext()
        engine = nil
    }
}
