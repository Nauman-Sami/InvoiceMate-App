import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/local/local_database.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init local DB
  await LocalDatabase.init();

  // Init Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const InvoiceApp());
}

class InvoiceApp extends StatelessWidget {
  const InvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'InvoiceMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController());
      }),
      initialRoute: '/splash',
      getPages: AppRoutes.pages,
    );
  }
}
