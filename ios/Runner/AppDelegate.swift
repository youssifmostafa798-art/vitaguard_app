import AVFoundation
import AudioToolbox
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let alertChannelName = "vitaguard/alerts"
  private var sirenPlayer: AVAudioPlayer?
  private var vibrationTimer: Timer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: alertChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(FlutterError(code: "unavailable", message: "App delegate unavailable", details: nil))
          return
        }

        switch call.method {
        case "startCriticalAlert":
          self.startCriticalAlert()
          result(nil)
        case "stopCriticalAlert":
          self.stopCriticalAlert()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func startCriticalAlert() {
    configureAudioSession()

    if sirenPlayer == nil, let sirenUrl = sirenAssetUrl() {
      sirenPlayer = try? AVAudioPlayer(contentsOf: sirenUrl)
      sirenPlayer?.numberOfLoops = -1
      sirenPlayer?.volume = 1.0
      sirenPlayer?.prepareToPlay()
    }

    if sirenPlayer?.isPlaying != true {
      sirenPlayer?.play()
    }

    startVibrationLoop()
  }

  private func stopCriticalAlert() {
    sirenPlayer?.stop()
    sirenPlayer = nil
    vibrationTimer?.invalidate()
    vibrationTimer = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
  }

  private func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
    try? session.setActive(true)
  }

  private func startVibrationLoop() {
    vibrationTimer?.invalidate()
    vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: true) { _ in
      AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
  }

  private func sirenAssetUrl() -> URL? {
    let registrar = self.registrar(forPlugin: "VitaGuardAlertChannel")
    let assetKey = registrar.lookupKey(forAsset: "assets/sounds/critical_siren.wav")
    let assetPath = Bundle.main.bundlePath + "/" + assetKey
    return URL(fileURLWithPath: assetPath)
  }
}
