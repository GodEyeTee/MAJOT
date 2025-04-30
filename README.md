# Mytest app

multifuntion aplication

## data base sql editor 
```CREATE TABLE users (
  id uuid PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Getting Started

RBAC have 3 role :admin,editor,user
have main 3 future :hotel system,store shopping system, ocr scaner reader

## Project stucjture
```lib/
├── core/                           # Core utilities and infrastructure
│   ├── api/                        # API services & configurations
│   │   ├── dio_client.dart         # Dio HTTP client configuration
│   │   ├── api_interceptors.dart   # Request/response interceptors
│   │   ├── error_handlers.dart     # API error handling utilities
│   │   └── endpoints.dart          # API endpoint constants
│   ├── bloc/                       # Base bloc implementations
│   │   ├── app_bloc_observer.dart  # Custom BLoC observer for logging
│   │   └── base_bloc.dart          # Abstract base BLoC class
│   ├── cache/                      # Caching mechanisms
│   │   ├── shared_prefs_cache.dart # SharedPreferences implementation
│   │   └── secure_storage.dart     # Secure storage implementation
│   ├── constant/                   # App constants
│   │   ├── app_constants.dart      # Global app constants
│   │   ├── asset_paths.dart        # Asset file paths
│   │   └── api_constants.dart      # API related constants
│   ├── errors/                     # Error handling
│   │   ├── app_exceptions.dart     # Custom exception classes
│   │   ├── error_handler.dart      # Global error handler
│   │   └── failure.dart            # Failure result classes
│   ├── extensions/                 # Extension methods
│   │   ├── context_extensions.dart # BuildContext extensions
│   │   ├── string_extensions.dart  # String utility extensions
│   │   └── datetime_extensions.dart # DateTime helper extensions
│   ├── localization/               # Internationalization
│   │   ├── app_localizations.dart  # Localization delegate
│   │   ├── language_constants.dart # Language constants
│   │   └── localization_helper.dart # Helper for easy text access
│   ├── network/                    # Network utilities
│   │   ├── network_info.dart       # Network connectivity checker
│   │   └── connection_checker.dart # Internet connection status
│   ├── router/                     # Routing system
│   │   ├── app_router.dart         # Router configuration (GoRouter)
│   │   ├── route_guards.dart       # Authorization route guards
│   │   └── route_constants.dart    # Named route constants
│   ├── security/                   # Security utilities
│   │   ├── biometric_helper.dart   # Biometric authentication
│   │   ├── encryption_service.dart # Data encryption utilities
│   │   └── ssl_pinning.dart        # Certificate pinning
│   ├── themes/                     # App theming
│   │   ├── app_theme.dart          # Theme configuration
│   │   ├── app_colors.dart         # Color constants
│   │   ├── text_styles.dart        # Typography styles
│   │   └── theme_extensions.dart   # Custom theme extensions
│   ├── usecases/                   # Base usecase interfaces
│   │   └── usecase.dart            # UseCase base class
│   └── utils/                      # Utility functions
│       ├── app_config_loader.dart  # App configuration loader
│       ├── logger.dart             # Logging utility
│       ├── date_formatter.dart     # Date formatting utilities
│       └── validators.dart         # Input validation functions
│
├── features/                       # Feature modules
│   ├── auth/                       # Authentication feature
│   │   ├── data/                   # Data layer
│   │   │   ├── datasources/        # Data sources
│   │   │   │   ├── remote/         # Remote data sources
│   │   │   │   │   ├── firebase_auth_data_source.dart
│   │   │   │   │   └── supabase_user_data_source.dart
│   │   │   │   └── local/          # Local data sources
│   │   │   │       └── auth_local_data_source.dart
│   │   │   ├── models/             # Data models
│   │   │   │   ├── user_model.dart # User data model
│   │   │   │   └── credentials_model.dart # Login credentials model
│   │   │   └── repositories/       # Repository implementations
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/                 # Domain layer
│   │   │   ├── entities/           # Business entities
│   │   │   │   ├── user.dart       # User entity
│   │   │   │   └── user_role.dart  # User role enum
│   │   │   ├── repositories/       # Repository interfaces
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/           # Business logic
│   │   │       ├── sign_in_with_google.dart
│   │   │       ├── sign_in_with_email.dart
│   │   │       ├── sign_out.dart
│   │   │       └── get_current_user.dart
│   │   └── presentation/           # Presentation layer
│   │       ├── bloc/               # State management
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       ├── pages/              # UI pages
│   │       │   ├── login_page.dart
│   │       │   ├── signup_page.dart
│   │       │   └── forgot_password_page.dart
│   │       └── widgets/            # UI components
│   │           ├── login_form.dart
│   │           ├── social_login_buttons.dart
│   │           └── auth_text_field.dart
│   │
│   ├── hotel_booking/              # Hotel Booking feature
│   │   ├── data/                   # Data layer
│   │   │   ├── datasources/        # Data sources
│   │   │   │   ├── remote/         # Remote data sources
│   │   │   │   │   └── hotel_api_service.dart
│   │   │   │   └── local/          # Local data sources
│   │   │   │       └── hotel_cache_service.dart
│   │   │   ├── models/             # Data models
│   │   │   │   ├── hotel_model.dart
│   │   │   │   ├── room_model.dart
│   │   │   │   └── booking_model.dart
│   │   │   └── repositories/       # Repository implementations
│   │   │       └── hotel_repository_impl.dart
│   │   ├── domain/                 # Domain layer
│   │   │   ├── entities/           # Business entities
│   │   │   │   ├── hotel.dart
│   │   │   │   ├── room.dart
│   │   │   │   └── booking.dart
│   │   │   ├── repositories/       # Repository interfaces
│   │   │   │   └── hotel_repository.dart
│   │   │   └── usecases/           # Business logic
│   │   │       ├── search_hotels.dart
│   │   │       ├── get_hotel_details.dart
│   │   │       ├── book_room.dart
│   │   │       └── get_bookings.dart
│   │   └── presentation/           # Presentation layer
│   │       ├── bloc/               # State management
│   │       │   ├── hotel_search/   # Hotel search flow
│   │       │   │   ├── hotel_search_bloc.dart
│   │       │   │   ├── hotel_search_event.dart
│   │       │   │   └── hotel_search_state.dart
│   │       │   └── booking/        # Booking flow
│   │       │       ├── booking_bloc.dart
│   │       │       ├── booking_event.dart
│   │       │       └── booking_state.dart
│   │       ├── pages/              # UI pages
│   │       │   ├── hotel_search_page.dart
│   │       │   ├── hotel_detail_page.dart
│   │       │   ├── room_selection_page.dart
│   │       │   ├── booking_confirmation_page.dart
│   │       │   └── booking_history_page.dart
│   │       └── widgets/            # UI components
│   │           ├── hotel_card.dart
│   │           ├── room_card.dart
│   │           ├── date_range_picker.dart
│   │           └── booking_summary.dart
│   │
│   ├── shopping/                   # Shopping feature
│   │   ├── data/                   # Data layer
│   │   │   ├── datasources/        # Data sources
│   │   │   │   ├── remote/         # Remote data sources
│   │   │   │   │   └── products_api_service.dart
│   │   │   │   └── local/          # Local data sources
│   │   │   │       └── cart_local_storage.dart
│   │   │   ├── models/             # Data models
│   │   │   │   ├── product_model.dart
│   │   │   │   ├── cart_item_model.dart
│   │   │   │   └── order_model.dart
│   │   │   └── repositories/       # Repository implementations
│   │   │       ├── product_repository_impl.dart
│   │   │       ├── cart_repository_impl.dart
│   │   │       └── order_repository_impl.dart
│   │   ├── domain/                 # Domain layer
│   │   │   ├── entities/           # Business entities
│   │   │   │   ├── product.dart
│   │   │   │   ├── cart_item.dart
│   │   │   │   └── order.dart
│   │   │   ├── repositories/       # Repository interfaces
│   │   │   │   ├── product_repository.dart
│   │   │   │   ├── cart_repository.dart
│   │   │   │   └── order_repository.dart
│   │   │   └── usecases/           # Business logic
│   │   │       ├── get_products.dart
│   │   │       ├── search_products.dart
│   │   │       ├── add_to_cart.dart
│   │   │       ├── update_cart_item.dart
│   │   │       ├── remove_from_cart.dart
│   │   │       ├── get_cart.dart
│   │   │       ├── checkout.dart
│   │   │       └── get_orders.dart
│   │   └── presentation/           # Presentation layer
│   │       ├── bloc/               # State management
│   │       │   ├── products/       # Products management
│   │       │   │   ├── products_bloc.dart
│   │       │   │   ├── products_event.dart
│   │       │   │   └── products_state.dart
│   │       │   ├── cart/           # Cart management
│   │       │   │   ├── cart_bloc.dart
│   │       │   │   ├── cart_event.dart
│   │       │   │   └── cart_state.dart
│   │       │   └── order/          # Order management
│   │       │       ├── order_bloc.dart
│   │       │       ├── order_event.dart
│   │       │       └── order_state.dart
│   │       ├── pages/              # UI pages
│   │       │   ├── products_page.dart
│   │       │   ├── product_details_page.dart
│   │       │   ├── cart_page.dart
│   │       │   ├── checkout_page.dart
│   │       │   └── orders_history_page.dart
│   │       └── widgets/            # UI components
│   │           ├── product_card.dart
│   │           ├── cart_item_widget.dart
│   │           ├── payment_method_selector.dart
│   │           └── order_summary.dart
│   │
│   ├── ocr_scanner/                # OCR Scanner feature
│   │   ├── data/                   # Data layer
│   │   │   ├── datasources/        # Data sources
│   │   │   │   ├── remote/         # Remote data sources
│   │   │   │   │   └── ocr_api_service.dart
│   │   │   │   └── local/          # Local data sources
│   │   │   │       └── scan_history_storage.dart
│   │   │   ├── models/             # Data models
│   │   │   │   ├── scan_result_model.dart
│   │   │   │   └── scan_history_model.dart
│   │   │   └── repositories/       # Repository implementations
│   │   │       └── ocr_repository_impl.dart
│   │   ├── domain/                 # Domain layer
│   │   │   ├── entities/           # Business entities
│   │   │   │   ├── scan_result.dart
│   │   │   │   └── scan_history.dart
│   │   │   ├── repositories/       # Repository interfaces
│   │   │   │   └── ocr_repository.dart
│   │   │   └── usecases/           # Business logic
│   │   │       ├── scan_image.dart
│   │   │       ├── save_scan_result.dart
│   │   │       └── get_scan_history.dart
│   │   └── presentation/           # Presentation layer
│   │       ├── bloc/               # State management
│   │       │   ├── ocr_bloc.dart
│   │       │   ├── ocr_event.dart
│   │       │   └── ocr_state.dart
│   │       ├── pages/              # UI pages
│   │       │   ├── scanner_page.dart
│   │       │   ├── scan_result_page.dart
│   │       │   └── scan_history_page.dart
│   │       └── widgets/            # UI components
│   │           ├── camera_preview.dart
│   │           ├── scan_controls.dart
│   │           └── text_recognition_result.dart
│   │
│   ├── profile/                    # Profile feature
│   │   ├── data/                   # Data layer
│   │   │   ├── datasources/        # Data sources
│   │   │   │   ├── remote/         # Remote data sources
│   │   │   │   │   └── profile_api_service.dart
│   │   │   │   └── local/          # Local data sources
│   │   │   │       └── profile_local_storage.dart
│   │   │   ├── models/             # Data models
│   │   │   │   └── profile_model.dart
│   │   │   └── repositories/       # Repository implementations
│   │   │       └── profile_repository_impl.dart
│   │   ├── domain/                 # Domain layer
│   │   │   ├── entities/           # Business entities
│   │   │   │   └── profile.dart
│   │   │   ├── repositories/       # Repository interfaces
│   │   │   │   └── profile_repository.dart
│   │   │   └── usecases/           # Business logic
│   │   │       ├── get_profile.dart
│   │   │       ├── update_profile.dart
│   │   │       └── change_password.dart
│   │   └── presentation/           # Presentation layer
│   │       ├── bloc/               # State management
│   │       │   ├── profile_bloc.dart
│   │       │   ├── profile_event.dart
│   │       │   └── profile_state.dart
│   │       ├── pages/              # UI pages
│   │       │   ├── profile_page.dart
│   │       │   ├── edit_profile_page.dart
│   │       │   └── change_password_page.dart
│   │       └── widgets/            # UI components
│   │           ├── profile_header.dart
│   │           ├── profile_menu_item.dart
│   │           └── profile_image_picker.dart
│   │
│   └── admin_dashboard/            # Admin Dashboard feature
│       ├── data/                   # Data layer
│       │   ├── datasources/        # Data sources
│       │   │   └── remote/         # Remote data sources
│       │   │       ├── admin_api_service.dart
│       │   │       ├── analytics_api_service.dart
│       │   │       └── user_management_api_service.dart
│       │   ├── models/             # Data models
│       │   │   ├── analytics_model.dart
│       │   │   ├── user_management_model.dart
│       │   │   └── role_model.dart
│       │   └── repositories/       # Repository implementations
│       │       ├── admin_repository_impl.dart
│       │       ├── analytics_repository_impl.dart
│       │       └── user_management_repository_impl.dart
│       ├── domain/                 # Domain layer
│       │   ├── entities/           # Business entities
│       │   │   ├── analytics_data.dart
│       │   │   ├── user_management.dart
│       │   │   └── role.dart
│       │   ├── repositories/       # Repository interfaces
│       │   │   ├── admin_repository.dart
│       │   │   ├── analytics_repository.dart
│       │   │   └── user_management_repository.dart
│       │   └── usecases/           # Business logic
│       │       ├── get_analytics.dart
│       │       ├── get_users.dart
│       │       ├── update_user.dart
│       │       ├── delete_user.dart
│       │       ├── assign_role.dart
│       │       └── get_roles.dart
│       └── presentation/           # Presentation layer
│           ├── bloc/               # State management
│           │   ├── analytics/      # Analytics management
│           │   │   ├── analytics_bloc.dart
│           │   │   ├── analytics_event.dart
│           │   │   └── analytics_state.dart
│           │   └── user_management/ # User management
│           │       ├── user_management_bloc.dart
│           │       ├── user_management_event.dart
│           │       └── user_management_state.dart
│           ├── pages/              # UI pages
│           │   ├── dashboard_page.dart
│           │   ├── analytics_page.dart
│           │   ├── user_management_page.dart
│           │   └── role_management_page.dart
│           └── widgets/            # UI components
│               ├── analytics_chart.dart
│               ├── sales_summary.dart
│               ├── user_table.dart
│               └── role_editor.dart
│
├── common/                         # Shared code across features
│   ├── widgets/                    # Shared widgets
│   │   ├── app_button.dart         # Custom styled buttons
│   │   ├── app_text_field.dart     # Custom text field
│   │   ├── loading_indicator.dart  # Loading animation
│   │   ├── error_view.dart         # Error UI component
│   │   └── empty_state.dart        # Empty state UI component
│   ├── models/                     # Shared models
│   │   ├── result.dart             # Result wrapper (success/failure)
│   │   └── pagination.dart         # Pagination data model
│   └── extensions/                 # Shared extensions
│       └── widget_extensions.dart  # Widget utility extensions
│
├── services/                       # Global services
│   ├── rbac/                       # Role-Based Access Control
│   │   ├── role_manager.dart       # Role management service
│   │   ├── permission.dart         # Permission model
│   │   └── permission_guard.dart   # UI permission guard widget
│   ├── analytics/                  # Analytics tracking
│   │   ├── analytics_service.dart  # Analytics tracking service
│   │   └── event_constants.dart    # Analytics event names
│   ├── navigation/                 # Navigation service
│   │   └── navigation_service.dart # Navigation helper
│   └── notification/               # Push notifications
│       ├── notification_service.dart # Notification handler
│       └── notification_mapper.dart # Maps payload to UI
│
├── di/                             # Dependency Injection
│   ├── service_locator.dart        # Service locator configuration
│   ├── feature_dependencies.dart   # Feature-specific dependencies
│   └── core_dependencies.dart      # Core dependencies
│
├── config/                         # Configuration
│   ├── app_config.dart             # Environment configuration
│   ├── environment.dart            # Environment enum
│   └── build_config.dart           # Build-specific configuration
│
├── app.dart                        # App configuration
└── main.dart                       # Application entry point
```

## 1. สถาปัตยกรรมซอฟต์แวร์ (Modular + Feature-First)
- แยกแต่ละฟีเจอร์เป็นแพ็กเกจย่อย (Dart package) มีโฟลเดอร์ UI, domain, data ภายใน เพื่อให้ build/test/deploy แยกกันได้ง่ายและลด dependency conflict [Medium](https://medium.com/%40punithsuppar7795/flutter-modular-architecture-how-to-structure-a-scalable-app-4c3b31a7514c?utm_source=chatgpt.com) [Medium](https://medium.com/flutter-community/a-modular-flutter-project-approach-c7ea8f9bfd70?utm_source=chatgpt.com)
- ใช้เลเยอร์ Domain (Entities, UseCases), Data (Repositories, API), Presentation (Widgets, ViewModels) แต่รวมไฟล์ของแต่ละฟีเจอร์ไว้ในโฟลเดอร์เดียว (feature-first) เพื่อ readability ลด ceremony ของ Clean Architecture ดั้งเดิม [Code With Andrea](https://codewithandrea.com/articles/flutter-project-structure/?utm_source=chatgpt.com) [DEV Community](https://dev.to/princetomarappdev/mastering-flutter-architecture-from-clean-to-feature-first-for-faster-scalable-development-4605?utm_source=chatgpt.com)
## 2. การควบคุมสิทธิ์ (RBAC)
- จัดการบทบาท 3 แบบ (admin, user, staff) โดยกำหนด permissions per module/action ใน central RoleManager class แล้วเชื่อมกับ GoRouter middleware เพื่อ guard routes [Medium](https://medium.com/%40m.goudjal.y/implementing-role-based-access-control-in-flutter-ui-with-gorouter-df4551c4930f?utm_source=chatgpt.com) [tula.co](https://tula.co/blog/user-access-model-rbac-in-flutter-ui/?utm_source=chatgpt.com)
- แต่ละ widget ที่ต้องการสิทธิ์เฉพาะ ให้ตรวจสอบผ่าน RoleManager.hasPermission(…) ก่อน render ลด if-else กระจัดกระจายในโค้ด [DEV Community](https://dev.to/sparshmalhotra/role-based-access-control-in-flutter-4m6c?utm_source=chatgpt.com)
## 3. โมดูลหลัก (Modules)
### 3.1 Hotel Booking
- โครงสร้าง: ```feature/hotel_booking/{data,domain,presentation}```
- ฟีเจอร์: ค้นหาห้อง, จอง, ดูสถานะการจอง, ปฏิทินราคา [WTF Blog GitHub](https://blog.flutter.wtf/hotel-booking-app-development/?utm_source=chatgpt.com)
### 3.2 Shopping
- โครงสร้าง: ```feature/shopping/{data,domain,presentation}```
- ฟีเจอร์: สินค้า, ตะกร้า, ชำระเงิน, order history [Medium](https://medium.com/flutter-community/flutter-shopping-basket-architecture-with-provider-8e91f496ad4c?utm_source=chatgpt.com) [Medium](https://medium.com/flutter-community/flutter-shopping-app-prototype-lessons-learned-16d6646bbed7?utm_source=chatgpt.com)
### 3.3 Profile
- โครงสร้าง: ```feature/profile/{data,domain,presentation}```
- ฟีเจอร์: แก้ไขข้อมูลผู้ใช้, เปลี่ยนรหัสผ่าน, ตั้งค่าภาษา/ธีม
### 3.4 Admin Dashboard
- โครงสร้าง: ```feature/admin_dashboard/{data,domain,presentation}```
- ฟีเจอร์: สรุปรายงานยอดจอง/ยอดขาย, จัดการผู้ใช้, ตั้งค่าสิทธิ์ [Medium](https://medium.com/%40htsuruo/how-to-develop-a-simple-modern-admin-dashboard-with-flutter-web-f507a9d0ab9c?utm_source=chatgpt.com) [GitHub](https://github.com/abuanwar072/Flutter-Responsive-Admin-Panel-or-Dashboard?utm_source=chatgpt.com)
## 4. การจัดการสถานะ (State Management)
- <b>Riverpod 2.x</b> สำหรับ global & async state (caching, API calls) [Medium](https://santhosh-adiga-u.medium.com/flutter-app-architecture-and-best-practices-b7752b41d3f2?utm_source=chatgpt.com)
- <b>Bloc + Freezed</b> สำหรับ flows ที่ซับซ้อนต้อง test ชัดเจน (เช่น การชำระเงิน) [DEV Community](https://dev.to/sparshmalhotra/role-based-access-control-in-flutter-4m6c?utm_source=chatgpt.com)
- <b>Signals</b> สำหรับ local widget state เบาๆ ตอบสนองเร็ว
## 5. สองภาษา (i18n)
- ใช้ ```flutter_localizations``` + Dart ```intl``` กับ ARB files (```intl_en.arb, intl_th.arb```) ตั้ง ```supportedLocales``` ใน MaterialApp [Flutter documentation](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization?utm_source=chatgpt.com) [Medium](https://medium.com/%40punithsuppar7795/internationalization-i18n-and-localization-l10n-in-flutter-supporting-multiple-languages-e83c171ce9c6?utm_source=chatgpt.com)
- สลับภาษาได้แบบไดนามิกโดยเก็บ locale ใน Riverpod/Bloc แล้วรีเฟรช MaterialApp(locale: currentLocale) [Medium](https://medium.com/%40punithsuppar7795/internationalization-i18n-and-localization-l10n-in-flutter-supporting-multiple-languages-e83c171ce9c6?utm_source=chatgpt.com)
## 6. ธีมไดนามิก (Theming)
- กำหนด ```ThemeData lightTheme``` และ ```darkTheme``` พร้อม ```themeMode``` ควบคุมด้วย state [Medium](https://medium.com/%40leadnatic/building-dynamic-themes-in-flutter-a-designers-guide-535879e3aea4?utm_source=chatgpt.com)
- ใช้ <b>Theme Extension</b> เพิ่ม custom properties (colors, paddings) ให้ type-safe และ modular [Medium](https://medium.com/%40leadnatic/building-dynamic-themes-in-flutter-a-designers-guide-535879e3aea4?utm_source=chatgpt.com)
## 7. ความปลอดภัย (Security)
- เก็บ tokens ด้วย ```flutter_secure_storage``` พร้อม fallback error handling [Touchlane](https://touchlane.com/building-a-secure-flutter-app/?utm_source=chatgpt.com)
- ใช้ Biometric (```local_auth```) พร้อมตรวจ compatibility ก่อนเรียกใช้งาน [Touchlane](https://touchlane.com/building-a-secure-flutter-app/?utm_source=chatgpt.com)
- Obfuscate code ด้วย ```--obfuscate --split-debug-info``` ป้องกัน reverse-engineering [Medium](https://medium.com/%40subhashchandrashukla/securing-your-flutter-app-best-practices-for-obfuscation-encryption-and-endpoint-protection-d0361666eecf?utm_source=chatgpt.com)
- เปิด HTTPS + certificate pinning ผ่าน Dio interceptor หรือ native plugin [Flutter documentation](https://docs.flutter.dev/security?utm_source=chatgpt.com)
