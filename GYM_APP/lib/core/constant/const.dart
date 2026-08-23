// Overridable at build/run time so the backend's LAN IP doesn't have to be
// hand-edited here every time it changes:
//   flutter run --dart-define=API_BASE_URL=http://192.168.1.23:8000/api/api_v1
// Falls back to the previous hardcoded value when no override is given, so
// nothing changes for anyone who doesn't pass the flag.
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://172.20.10.2:8000/api/api_v1',
);
const String googleServerClientId = "734425846833-a8ol95scf8u14dbs6pvt6mco7gn2f3c5.apps.googleusercontent.com";
final String storageBaseUrl = baseUrl.replaceFirst('/api/api_v1', '') + '/storage';
