import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let flutterEngine = FlutterEngine(name: "my_engine")
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)

    let flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = flutterViewController
    window?.makeKeyAndVisible()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
