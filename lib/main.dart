import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:homeventory/providers/expense_provider.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/household_provider.dart';
import 'services/api_service.dart';
import 'router.dart';
import 'constants.dart';

void main() {
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

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = createRouter(_authProvider);
    ApiService().onSessionExpired = () => _authProvider.forceLogout();
  }

  @override 
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => HouseholdProvider()),
      ],
      child: MaterialApp.router(
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