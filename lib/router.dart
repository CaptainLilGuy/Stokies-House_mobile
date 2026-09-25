import 'package:go_router/go_router.dart';
import 'package:homeventory/models/inventory_item.dart';
import 'package:homeventory/screens/inventory/inventory_list_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/inventory/add_item_screen.dart';
import 'screens/inventory/edit_item_screen.dart';
import 'screens/expenses/expense_screen.dart';
import 'screens/household/household_screen.dart';
import 'screens/inventory/category_management_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/inventory/receipt_scan_screen.dart';
import 'screens/inventory/receipt_review_screen.dart';
import 'screens/inventory/receipt_submit_summary_screen.dart';
import 'screens/expenses/add_expense_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loggedIn = authProvider.isLoggedIn;
      final checked = authProvider.hasCheckedAuth;
      final goingToSplah = state.matchedLocation == '/';
      final goingToAuth = state.matchedLocation == '/login' || 
          state.matchedLocation == '/register';

      if (!checked) {
        return goingToSplah ? null : '/';
      }
      if (!loggedIn && !goingToAuth) {
        return '/login';
      }
      if (loggedIn && (goingToAuth || goingToSplah)) {
        return '/inventory';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (ctx, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (ctx, state) => const RegisterScreen()),
      GoRoute(path: '/inventory', builder: (ctx, state) => const InventoryListScreen()),
      GoRoute(path: '/inventory/add', builder: (ctx, state) => const AddItemScreen()),
      GoRoute(path: '/household', builder: (ctx, state) => const HouseholdScreen()),
      GoRoute(path: '/expenses', builder: (ctx, state) => const ExpenseScreen()),
      GoRoute(path: '/inventory/categories', builder: (ctx, state) => const CategoryManagementScreen()),
      GoRoute(path: '/inventory/scan-receipt', builder: (ctx, state) => const ReceiptScanScreen()),
      GoRoute(path: '/inventory/scan-receipt/review',
        builder: (ctx, state) {
          final data = state.extra as Map<String, dynamic>;
          return ReceiptReviewScreen(parsedData: data);
        },
      ),
      GoRoute(
        path: '/inventory/edit', 
        builder: (ctx, state) {
          final item = state.extra as InventoryItem;
          return EditItemScreen(item: item);
        },
      ),
      GoRoute(
        path: '/inventory/scan-receipt/summary',
        builder: (ctx, state) {
          final data = state.extra as Map<String, dynamic>;
          return ReceiptSubmitSummaryScreen(
            results: data['results'] as List<Map<String, dynamic>>,
            total: data['total'] as int?,
            date: data['date'] as String?
          );
        },
      ),
      GoRoute(
        path: '/inventory/add-expense', 
        builder: (ctx, state) {
          final extra =  state.extra as Map<String, dynamic>?;
          return AddExpenseScreen(
            initialDescription: extra?['description'] as String?,
            initialAmount: extra?['amount'] as double?,
            initialDate: extra?['date'] as DateTime?,
            source: extra?['source'] as String? ?? 'manual',
          );
        }),
    ],
  );
}




// final appRouter = GoRouter(
//   
  
// );