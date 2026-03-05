import AuthenticationServices
import Flutter
import UIKit

// ──────────────────────────────────────────────────────────────────────────────
//  AppDelegate
//
//  Registers the "com.cipherowl/autofill" MethodChannel so the Flutter/Dart
//  AutofillBridge can write and clear the credential cache that the
//  AutoFillExtension reads from the shared App Group UserDefaults.
// ──────────────────────────────────────────────────────────────────────────────

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  // ── Constants — must match CredentialProviderViewController.swift ──────────
  private static let appGroupID = "group.com.cipherowl.cipherowl"
  private static let cacheKey   = "cipher_owl_autofill_cache"
  private static let channel    = "com.cipherowl/autofill"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    setupAutofillChannel(registry: engineBridge.pluginRegistry)
  }

  // ── MethodChannel setup ───────────────────────────────────────────────────

  private func setupAutofillChannel(registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "AutofillBridge")?.messenger() else {
      return
    }

    let channel = FlutterMethodChannel(
      name: Self.channel,
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {

      case "updateAutofillCache":
        guard let args = call.arguments as? [String: Any],
              let json = args["cache"] as? String
        else { result(FlutterError(code: "BAD_ARGS", message: "cache string required", details: nil)); return }
        self.writeCache(json)
        if #available(iOS 12.0, *) { self.refreshCredentialIdentityStore(json) }
        result(nil)

      case "clearAutofillCache":
        self.clearCache()
        if #available(iOS 12.0, *) { ASCredentialIdentityStore.shared.removeAllCredentialIdentities { _, _ in } }
        result(nil)

      case "isAutofillServiceEnabled":
        // iOS AutoFill via extension is always "available": the user controls it in Settings.
        result(true)

      case "requestEnableAutofillService":
        // Deep-link to Passwords & Accounts settings pane.
        if let url = URL(string: UIApplication.openSettingsURLString) {
          DispatchQueue.main.async { UIApplication.shared.open(url) }
        }
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // ── Cache helpers ─────────────────────────────────────────────────────────

  private func writeCache(_ json: String) {
    UserDefaults(suiteName: Self.appGroupID)?.set(json, forKey: Self.cacheKey)
  }

  private func clearCache() {
    UserDefaults(suiteName: Self.appGroupID)?.removeObject(forKey: Self.cacheKey)
  }

  /// Populate ASCredentialIdentityStore so iOS can surface credentials in the
  /// QuickType bar without launching the extension UI.
  @available(iOS 12.0, *)
  private func refreshCredentialIdentityStore(_ json: String) {
    guard
      let data  = json.data(using: .utf8),
      let raw   = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
    else { return }

    var identities: [ASPasswordCredentialIdentity] = []

    for dict in raw {
      guard
        let id       = dict["id"]       as? String,
        let username = dict["username"] as? String,
        let url      = dict["url"]      as? String,
        !url.isEmpty, !username.isEmpty
      else { continue }

      let serviceID = ASCredentialServiceIdentifier(
        identifier: url,
        type: url.hasPrefix("http") ? .URL : .domain
      )
      let identity = ASPasswordCredentialIdentity(
        serviceIdentifier: serviceID,
        user:              username,
        recordIdentifier:  id
      )
      identities.append(identity)
    }

    guard !identities.isEmpty else { return }

    ASCredentialIdentityStore.shared.replaceCredentialIdentities(
      with: identities
    ) { _, _ in }
  }
}
