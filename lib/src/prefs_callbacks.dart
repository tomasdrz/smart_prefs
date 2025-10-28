/// Callback function type for checking network connectivity.
///
/// Should return `true` if the device has network connectivity,
/// `false` otherwise.
///
/// This is used by the retry mechanism to avoid unnecessary attempts
/// when the device is offline.
///
/// Example using connectivity_plus package:
/// ```dart
/// import 'package:connectivity_plus/connectivity_plus.dart';
///
/// Prefs.setConnectivityChecker(() async {
///   final result = await Connectivity().checkConnectivity();
///   return result != ConnectivityResult.none;
/// });
/// ```
typedef ConnectivityChecker = Future<bool> Function();

/// Callback function type for being notified when remote preferences load.
///
/// [success] indicates whether the load was successful.
/// [attempt] is the number of attempts made (starts at 1).
///
/// This is useful for:
/// - Updating UI when remote data becomes available
/// - Showing offline mode banners when loading fails
/// - Triggering data refresh in the app
///
/// Example:
/// ```dart
/// Prefs.setRemoteLoadCallback((bool success, int attempt) {
///   if (success) {
///     print('✅ Remote prefs loaded on attempt $attempt');
///     // Update UI with fresh data
///     MyApp.refreshRemoteData();
///   } else {
///     print('❌ Failed after $attempt attempts');
///     // Show offline mode banner
///     MyApp.showOfflineBanner();
///   }
/// });
/// ```
typedef RemoteLoadCallback = void Function(bool success, int attempt);
