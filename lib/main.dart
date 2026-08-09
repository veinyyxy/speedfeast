import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import '../Controller/service_provider.dart';

import 'home_page_exclusive2.dart';
import 'Notifications/buyer_notification_router.dart';
import 'Notifications/buyer_notification_service.dart';
import 'Notifications/notification_center_page.dart';
import 'OrderPage/order_page.dart';
import 'OrderPage/recent_order_page.dart';
import 'OrderPage/dine_in_scan_page.dart';
import 'MoreMenu/more_main_menu.dart';
import 'MoreMenu/more_my_account_personal_info.dart';
import 'MoreMenu/rewards_activity_page.dart';
import 'Payment/add_payment_method.dart';
import 'Payment/payment_list_page.dart';
import 'RegisterPage/sign_up_screen.dart';
import 'RegisterPage/verification_page.dart';
import 'RegisterPage/mobile_number_page.dart';
import 'RegisterPage/base_info_page.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(
    buyerFirebaseMessagingBackgroundHandler,
  );
  final serviceProvider = ServiceProvider();
  await serviceProvider.initialize();
  await BuyerNotificationService.instance.initialize(
    onToken: serviceProvider.registerBuyerNotificationDeviceToken,
    onTap: (intent) async {
      if (intent.storeId.isNotEmpty &&
          intent.storeId != serviceProvider.activeStoreId) {
        final switched = await serviceProvider.selectStore(intent.storeId);
        if (!switched) return;
      }
      await BuyerNotificationRouter.handle(appNavigatorKey, intent);
    },
  );
  //await serviceProvider.loadConfig();
  //await serviceProvider.fetchInitData();

  runApp(
    ChangeNotifierProvider.value(value: serviceProvider, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ServiceProvider>().buyerAppTheme;

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: appTheme.toThemeData(),
      routes: {
        '/': (context) => const _BuyerRoot(),
        '/notifications': (context) => const NotificationCenterPage(),
        '/order_page': (context) => OrderPage(),
        '/order_page/recent_orders': (context) => RecentOrdersPage(),
        '/dine_in_scan': (context) => DineInScanPage(),
        '/more_page': (context) => MoreMainMenu(),
        '/more_page/personal_info': (context) => PersonalInfoPage(),
        '/more_page/payment_options': (context) => AddPaymentMethodPage(),
        '/more_page/payment_options/payment_list': (context) =>
            PaymentListPage(),
        '/more_page/rewards_activity': (context) => RewardsActivityPage(),
        'register/mobile_number_page': (context) => MobileNumberPage(),
        '/register/sign_up_screen': (context) => SignUpScreen(),
        '/register/VerificationPage': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;

          if (args is Map<String, dynamic>) {
            final String? emailAddress = args['email'] as String?;
            final String? phoneNumber = args['phone'] as String?; // 获取额外参数

            if (emailAddress == null && phoneNumber == null) {
              return const Text('Error: Email or Phone argument not provided');
            }
            final String emailOrPhoneValue = emailAddress ?? phoneNumber!;
            return VerificationPage(
              emailOrPhone: emailOrPhoneValue,
              type: emailAddress == null ? 'phone' : 'email',
              onVerificationSuccess: () {
                debugPrint(
                  '------------------Verification successful!-----------------------',
                );
                Navigator.pushNamed(
                  context,
                  '/register/base_info_page',
                  arguments: {'email': emailAddress, 'phone': phoneNumber},
                );
              },
            );
          }
          return const Text('Error: Invalid arguments for VerificationPage');
        },
        '/register/base_info_page': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Map<String, dynamic>) {
            final String? emailAddress = args['email'] as String?;
            final String? phoneNumber = args['phone'] as String?;
            return BaseInfoPage(phoneNumber, emailAddress);
          }
          return const Text('Error: Invalid arguments for BaseInfoPage');
        },
      },
      initialRoute: '/',
    );
  }

  /* @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menu Item Demo',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Menu Items'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Example with image (Paneer Paratha)
            ProductCard2(
              name: 'Paneer Paratha',
              price: 'CA\$5.99',
              description: 'Indian-style flatbread stuffed with paneer.',
              imageUrl: 'assets/images/cat.jpg', // Replace with your image asset
              initialCount: 0,
              onQuantityChanged: (count) => print("'Paneer Paratha' $count."),
              onTap: () {
                print('Tapped on Paneer Paratha item');
              },
            ),
            const SizedBox(height: 20),
            // Example without image (Aloo Tikki Noodle Kathi Roll)
            ProductCard2(
              name: 'Aloo Tikki Noodle Kathi Roll',
              price: 'CA\$10.99',
              description: 'Crispy potato patties wrapped in a flavorful noodle wrap.',
              initialCount: 0,
              onQuantityChanged: (count) => print("'Aloo Tikki Noodle Kathi Roll' $count."),
              onTap: () {
                print('Tapped on Aloo Tikki Noodle Kathi Roll item');
              },
            ),
            const SizedBox(height: 20),
            // Another example with image
            ProductCard2(
              name: 'Butter Chicken',
              price: 'CA\$15.50',
              description:
              'Tender chicken pieces cooked in a rich, creamy tomato sauce with aromatic spices. Served with a side of basmati rice.',
              imageUrl: 'assets/images/iphone15.jpg', // Replace with your image asset
              initialCount: 0,
              onQuantityChanged: (count) => print("'Butter Chicken' $count."),
              onTap: () {
                print('Tapped on Butter Chicken item');
              },
            ),
            const SizedBox(height: 20),
            // Another example without image (long description)
            ProductCard2(
              name: 'Vegetable Samosa',
              price: 'CA\$3.50',
              description:
              'Crispy pastry filled with spiced potatoes and peas. A classic Indian appetizer that\'s perfect for sharing or as a quick snack.',
              initialCount: 0,
              onQuantityChanged: (count) => print("'Vegetable Samosa' $count."),
              onTap: () {
                print('Tapped on Vegetable Samosa item');
              },
            ),
          ],
        ),
      ),
    );
  }*/
}

class _BuyerRoot extends StatelessWidget {
  const _BuyerRoot();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();
    if (!provider.buyerAccessAllowed) {
      return _BuyerAccessUnavailablePage(
        message: provider.buyerAccessError,
        isRetrying: provider.isCheckingBuyerAccess,
        onRetry: provider.retryBuyerAccess,
      );
    }
    return HomePage();
  }
}

class _BuyerAccessUnavailablePage extends StatelessWidget {
  const _BuyerAccessUnavailablePage({
    required this.message,
    required this.isRetrying,
    required this.onRetry,
  });

  final String? message;
  final bool isRetrying;
  final Future<bool> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Service is busy',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message?.trim().isNotEmpty == true
                        ? message!
                        : 'The current visitor capacity has been reached. Please try again shortly.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: isRetrying ? null : onRetry,
                    icon: isRetrying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(isRetrying ? 'Checking' : 'Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
