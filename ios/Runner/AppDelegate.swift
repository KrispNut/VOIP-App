import UIKit
import Flutter
import PushKit
import flutter_callkit_incoming

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)

        // Initialize VoIP Push
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - VoIP Token
    func pushRegistry(_ registry: PKPushRegistry,
                      didUpdate pushCredentials: PKPushCredentials,
                      for type: PKPushType) {

        let deviceToken = pushCredentials.token.map { String(format: "%02x", $0) }.joined()

        print("VoIP Token: \(deviceToken)")
        
        // Send this token to your server
    }

    // MARK: - Token Invalidated
    func pushRegistry(_ registry: PKPushRegistry,
                      didInvalidatePushTokenFor type: PKPushType) {

        print("VoIP token invalidated")
    }

    // MARK: - Receive VoIP Push
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      completion: @escaping () -> Void) {

        let data = payload.dictionaryPayload

        let uuid = UUID().uuidString
        let handle = data["caller"] as? String ?? "Unknown"
        let name = data["name"] as? String ?? "Incoming Call"

        let callData = flutter_callkit_incoming.Data(
            id: uuid,
            nameCaller: name,
            handle: handle,
            type: 0
        )

        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(callData, fromPushKit: true)

        completion()
    }
}

// import Flutter
// import UIKit
// import PushKit
// import flutter_callkit_incoming
//
// @main
// @objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     GeneratedPluginRegistrant.register(with: self)
//
//     // Register for VoIP pushes
//     let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
//     voipRegistry.delegate = self
//     voipRegistry.desiredPushTypes = [.voIP]
//
//     // Request notification permissions
//     if #available(iOS 10.0, *) {
//       UNUserNotificationCenter.current().delegate = self
//       let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//       UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
//     }
//     application.registerForRemoteNotifications()
//
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
//
//   // MARK: - PKPushRegistryDelegate
//
//   func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
//     let deviceToken = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
//     print("VoIP Push Token: \(deviceToken)")
//     SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
//   }
//
//   func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
//     SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
//   }
//
//   func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
//     guard type == .voIP else {
//       completion()
//       return
//     }
//
//     let data = payload.dictionaryPayload
//     let id = UUID().uuidString
//     let callerName = data["caller_name"] as? String ?? "Unknown Caller"
//     let handle = data["caller_ext"] as? String ?? ""
//
//     let callData = flutter_callkit_incoming.Data(id: id, nameCaller: callerName, handle: handle, type: 0)
//     callData.extra = data as NSDictionary
//     callData.appName = "VoIP App"
//     callData.duration = 30000
//
//     SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(callData, fromPushKit: true)
//     completion()
//   }
// }
