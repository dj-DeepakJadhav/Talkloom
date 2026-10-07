import 'package:talkloom_client/talkloom_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

// When you are running the app on a physical device, you need to set the
// server URL to the IP address of your computer. You can find the IP
// address by running `ipconfig` on Windows or `ifconfig` on Mac/Linux.
//
// You can set the variable when running or building your app like this:
// E.g. `flutter run --dart-define=SERVER_URL=https://api.example.com/`.
//
// Otherwise, the server URL is fetched from the assets/config.json file or
// defaults to http://$localhost:8080/ if not found.
final serverUrl = getServerUrl();

/// Sets up a global client object that can be used to talk to the server from
/// anywhere in our app. The client is generated from your server code
/// and is set up to connect to a Serverpod running on a local server on
/// the default port. You will need to modify this to connect to staging or
/// production servers.
/// In a larger app, you may want to use the dependency injection of your choice
/// instead of using a global client object. This is just a simple example.
late final Client client;

Future<void> initializeClient() async {
  // Serverpod applies this to the entire HTTP response, not just connecting.
  // Its 20-second default aborts AI compilation before repository recovery.
  // Interactive operations have shorter deadlines in LessonRepository.
  client =
      Client(await serverUrl, connectionTimeout: const Duration(minutes: 8))
        ..connectivityMonitor = FlutterConnectivityMonitor()
        ..authSessionManager = FlutterAuthSessionManager();
  // Restore persisted credentials before the router can start loading any
  // authenticated content. Starting the app first races protected calls
  // against session restoration and produces repeated 401 responses.
  await client.auth.initialize();
  try {
    await ensurePrivateSession();
  } catch (_) {
    // The recovery screen offers guest retry; never query private data without
    // a session and never require registration to recover connectivity.
  }
}

Future<void> ensurePrivateSession() async {
  if (client.auth.isAuthenticated) return;
  final guest = await client.anonymousIdp.login();
  await client.auth.updateSignedInUser(guest);
}

/// Account verification must not overwrite the guest's persisted credentials
/// before the server has successfully moved their learning data.
class MemoryAuthStorage implements ClientAuthSuccessStorage {
  AuthSuccess? _value;
  @override
  Future<AuthSuccess?> get() async => _value;
  @override
  Future<void> set(AuthSuccess? data) async {
    _value = data;
  }
}
