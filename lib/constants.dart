/// Central place for the API base URL and your student key.
/// Everything in the app reads from here - change nothing else.
class AppConstants {
  // The physical endpoint is always api.php; ?action=... selects the operation.
  static const String apiBase =
      'https://labs.anontech.info/cse489/exm3/api.php';

  // Used to build absolute image URLs, since the API returns relative paths
  // like "uploads/xxx.jpg".
  static const String serverBase = 'https://labs.anontech.info/cse489/exm3/';

  // Your assigned student key (sent as ?key=... on every request).
  static const String apiKey = '24341248';

  // WorkManager task identifiers.
  static const String pollJobTask = 'pollJobTask';
  static const String periodicSyncTask = 'periodicSyncTask';
}
