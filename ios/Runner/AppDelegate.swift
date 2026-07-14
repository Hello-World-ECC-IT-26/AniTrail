import Flutter
import CoreLocation
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let headingStreamHandler = DeviceHeadingStreamHandler()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String ?? ""
    if mapsApiKey.isEmpty || mapsApiKey.hasPrefix("$(") {
      assertionFailure("GoogleMapsApiKey is missing. Set MAPS_API_KEY in ios/Flutter/Local.xcconfig.")
    } else {
      GMSServices.provideAPIKey(mapsApiKey)
    }
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let headingChannel = FlutterEventChannel(
        name: "anitrail/device_heading",
        binaryMessenger: controller.binaryMessenger
      )
      headingChannel.setStreamHandler(headingStreamHandler)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

final class DeviceHeadingStreamHandler: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  private var eventSink: FlutterEventSink?

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.headingFilter = 1
    locationManager.headingOrientation = .portrait
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    guard CLLocationManager.headingAvailable() else {
      events(nil)
      return nil
    }
    locationManager.startUpdatingHeading()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    locationManager.stopUpdatingHeading()
    eventSink = nil
    return nil
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    guard heading >= 0 else { return }
    eventSink?(heading)
  }

  func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
    true
  }
}
