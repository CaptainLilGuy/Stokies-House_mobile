import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:homeventory/providers/expense_provider.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/household_provider.dart';
import 'providers/dashboard_provider.dart';
import 'services/api_service.dart';
import 'router.dart';
import 'constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ignore: avoid_print
  print('Using base URL: ${AppConstants.baseUrl}');
  runApp(const HomeventoryApp());
}

class HomeventoryApp extends StatefulWidget {
  const HomeventoryApp({super.key});

  @override
  State<StatefulWidget> createState() => _HomeventoryAppState();
}

class _HomeventoryAppState extends State<HomeventoryApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;
  late final DashboardProvider _dashboardProvider;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _dashboardProvider = DashboardProvider();
    _router = createRouter(_authProvider);
    ApiService().onSessionExpired = () => _authProvider.forceLogout();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().initMessageHandkers(
        messengerKey: _messengerKey, 
        router: _router, 
        onForegroundMessage: () {
          if (_authProvider.isLoggedIn) _dashboardProvider.fetch(silent: true);
        });
    });
  }

  @override 
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => HouseholdProvider()),  
        ChangeNotifierProvider.value(value: _dashboardProvider)
      ],
      child: MaterialApp.router(
        scaffoldMessengerKey: _messengerKey,
        title: 'Homeventory',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
        ),
      ),
    );
  }
}

// @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider()),
//         ChangeNotifierProvider(create: (_) => InventoryProvider()),
//         ChangeNotifierProvider(create: (_) => ExpenseProvider()),
//         ChangeNotifierProvider(create: (_) => HouseholdProvider()),
//       ],
//       child: Builder(
//         builder: (context) {
//           final authProvider = context.watch<AuthProvider>();
//           ApiService().onSessionExpired = () => authProvider.forceLogout();

//           return MaterialApp.router(
//             title: 'Homeventory',
//             debugShowCheckedModeBanner: false,
//             routerConfig: createRouter(authProvider),
//             theme: ThemeData(
//               colorSchemeSeed: Colors.teal,
//               useMaterial3: true,
//             ),
//           );
//         }
//       ),
//     );
//   }