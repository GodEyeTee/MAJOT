# Mytest app

multifuntion aplication

## Getting Started

RBAC have 3 role :admin,editor,user
have main 3 future :hotel system,store shopping system, ocr scaner reader

## Project stucjture
```lib/
├── core/                           # Core utilities and infrastructure
│   ├── api/                        # API services & configurations
│   ├── bloc/                       # Base bloc implementations
│   ├── cache/                      # Caching mechanisms
│   ├── constant/                   # App constants
│   ├── errors/                     # Error handling
│   ├── extensions/                 # Extension methods
│   ├── network/                    # Network utilities
│   ├── themes/                     # App theming
│   ├── usecases/                   # Base usecase interfaces
│   └── utils/                      # Utility functions
│       └── app_config_loader.dart  # Your existing config loader
│
├── features/                       # Feature modules
│   ├── auth/                       # Authentication feature
│   │   ├── data/                   # Data layer
│   │   │   ├── datasources/        # Data sources
│   │   │   │   ├── firebase_auth_data_source.dart
│   │   │   │   └── supabase_user_data_source.dart
│   │   │   ├── models/             # Data models
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/       # Repository implementations
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/                 # Domain layer
│   │   │   ├── entities/           # Business entities
│   │   │   │   └── user.dart
│   │   │   ├── repositories/       # Repository interfaces
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/           # Business logic
│   │   │       ├── sign_in_with_google.dart
│   │   │       └── sign_out.dart
│   │   └── presentation/           # Presentation layer
│   │       ├── bloc/               # State management
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       ├── pages/              # UI pages
│   │       │   └── login_page.dart
│   │       └── widgets/            # UI components
│
├── routes/                         # Navigation routing
│   └── routes.dart                 # Updated router configuration
│
├── widgets/                        # Shared widgets
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
