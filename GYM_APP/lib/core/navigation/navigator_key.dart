import 'package:flutter/material.dart';

/// App-wide navigator key, handed to [GetMaterialApp] in main.dart. Exists
/// so code with no [BuildContext] of its own — specifically [ApiClient]'s
/// 401 handling in api_client.dart — can still redirect to the login
/// screen when a session expires. Kept in its own file (no other imports)
/// to avoid a circular import between main.dart and api_client.dart.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
