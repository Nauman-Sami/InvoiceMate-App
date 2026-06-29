import 'package:get/get.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/invoices/screens/invoice_list_screen.dart';
import '../../features/invoices/screens/create_invoice_screen.dart';
import '../../features/invoices/screens/invoice_detail_screen.dart';
import '../../features/invoices/controllers/invoice_controller.dart';
import '../../features/clients/screens/clients_screen.dart';
import '../../features/clients/controllers/client_controller.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/products/controllers/product_controller.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/splash/screens/splash_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String invoices = '/invoices';
  static const String invoiceCreate = '/invoices/create';
  static const String invoiceDetail = '/invoices/detail';
  static const String clients = '/clients';
  static const String clientAdd = '/clients/add';
  static const String products = '/products';
  static const String profile = '/profile';

  // Ensures the data controllers exist for any route that needs them.
  // `fenix: true` recreates a controller if it was disposed after a pop,
  // so navigating directly to these routes never throws "not found".
  static final BindingsBuilder _dataBindings = BindingsBuilder(() {
    Get.lazyPut(() => InvoiceController(), fenix: true);
    Get.lazyPut(() => ClientController(), fenix: true);
    Get.lazyPut(() => ProductController(), fenix: true);
  });

  static final List<GetPage> pages = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => AuthController())),
    ),
    GetPage(
      name: home,
      page: () => const DashboardScreen(),
      binding: _dataBindings,
    ),
    GetPage(
      name: invoices,
      page: () => const InvoiceListScreen(),
      binding: _dataBindings,
    ),
    GetPage(
      name: invoiceCreate,
      page: () {
        final args = Get.arguments;
        return CreateInvoiceScreen(editInvoice: args != null ? args : null);
      },
      binding: _dataBindings,
    ),
    GetPage(
      name: invoiceDetail,
      page: () => const InvoiceDetailScreen(),
      binding: _dataBindings,
    ),
    GetPage(
      name: clients,
      page: () => const ClientsScreen(),
      binding: _dataBindings,
    ),
    GetPage(
      name: products,
      page: () => const ProductsScreen(),
      binding: _dataBindings,
    ),
    GetPage(name: profile, page: () => const ProfileScreen()),
  ];

  static GetPage get initialRoute {
    final auth = Get.find<AuthController>();
    return auth.user.value != null ? pages[1] : pages[0];
  }
}
