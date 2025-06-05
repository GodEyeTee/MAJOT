# คู่มือการพัฒนาต่อ Flutter App with Clean Architecture

## 📁 โครงสร้างโปรเจค

```
lib/
├── core/                    # ส่วนกลางที่ใช้ร่วมกันทั้งแอพ
│   ├── constants/          # ค่าคงที่
│   ├── di/                 # Dependency Injection
│   ├── errors/             # การจัดการ Error
│   ├── extensions/         # Extension methods
│   ├── network/            # Network utilities
│   ├── services/           # Services กลาง
│   ├── themes/             # Theme system
│   ├── usecases/           # Base use cases
│   └── utils/              # Utilities
├── features/               # ฟีเจอร์ต่างๆ แยกตาม domain
│   └── [feature_name]/     # แต่ละฟีเจอร์มีโครงสร้าง:
│       ├── data/           # Data layer
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/         # Business logic
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/   # UI layer
│           ├── bloc/
│           ├── pages/
│           └── widgets/
├── screens/                # หน้าจอหลัก
├── services/               # Services เฉพาะ (RBAC, etc.)
├── widgets/                # Shared widgets
├── app.dart               # App configuration
└── main.dart              # Entry point
```

## 🏗️ Architecture Pattern

### Clean Architecture + BLoC
```
UI (Pages/Widgets) 
    ↓↑ Events/States
BLoC (Business Logic)
    ↓↑ 
Use Cases (Domain Logic)
    ↓↑
Repository (Interface)
    ↓↑
Data Sources (API/Local)
```

## 📱 การเพิ่มหน้าใหม่

### 1. สร้าง Feature Structure
```bash
features/
└── your_feature/
    ├── data/
    │   ├── datasources/
    │   │   └── your_feature_remote_data_source.dart
    │   ├── models/
    │   │   └── your_model.dart
    │   └── repositories/
    │       └── your_feature_repository_impl.dart
    ├── domain/
    │   ├── entities/
    │   │   └── your_entity.dart
    │   ├── repositories/
    │   │   └── your_feature_repository.dart
    │   └── usecases/
    │       └── get_your_data.dart
    └── presentation/
        ├── bloc/
        │   ├── your_feature_bloc.dart
        │   ├── your_feature_event.dart
        │   └── your_feature_state.dart
        ├── pages/
        │   └── your_feature_page.dart
        └── widgets/
            └── your_custom_widget.dart
```

### 2. Entity (Domain Layer)
```dart
// domain/entities/product.dart
import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final double price;

  const Product({
    required this.id,
    required this.name,
    required this.price,
  });

  @override
  List<Object> get props => [id, name, price];
}
```

### 3. Model (Data Layer)
```dart
// data/models/product_model.dart
import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      price: json['price']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }
}
```

### 4. Repository
```dart
// domain/repositories/product_repository.dart
abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts();
  Future<Either<Failure, Product>> getProduct(String id);
}

// data/repositories/product_repository_impl.dart
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  
  ProductRepositoryImpl({required this.remoteDataSource});
  
  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final products = await remoteDataSource.getProducts();
      return Right(products);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
```

### 5. BLoC
```dart
// presentation/bloc/product_bloc.dart
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProducts getProductsUseCase;
  
  ProductBloc({required this.getProductsUseCase}) : super(ProductInitial()) {
    on<LoadProductsEvent>(_onLoadProducts);
  }
  
  Future<void> _onLoadProducts(
    LoadProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    
    final result = await getProductsUseCase(NoParams());
    
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductLoaded(products)),
    );
  }
}
```

### 6. Page
```dart
// presentation/pages/product_page.dart
class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is ProductError) {
            return Center(child: Text(state.message));
          }
          
          if (state is ProductLoaded) {
            return ListView.builder(
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                final product = state.products[index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text('฿${product.price}'),
                );
              },
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

### 7. เพิ่มใน Dependency Injection
```dart
// core/di/injection_container.dart
Future<void> _registerProductFeature() async {
  // Data sources
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(supabaseClient: sl()),
  );
  
  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(remoteDataSource: sl()),
  );
  
  // Use cases
  sl.registerLazySingleton(() => GetProducts(sl()));
  
  // BLoC
  sl.registerFactory(
    () => ProductBloc(getProductsUseCase: sl()),
  );
}
```

### 8. เพิ่ม Route
```dart
// lib/app.dart - ใน _createRouter()
GoRoute(
  path: 'products',
  builder: (context, state) => const ProductPage(),
),
```

## 🎨 Theme System

### การใช้ Theme
```dart
// ดึง theme colors
final primaryColor = Theme.of(context).primaryColor;
final bgColor = Theme.of(context).scaffoldBackgroundColor;

// ใช้ custom colors
final successColor = context.customColors.success;

// ใช้ typography
final headlineStyle = context.typography.h1;

// ใช้ spacing
const padding = AppSpacing.md; // 16px
AppSpacing.verticalGapLg // SizedBox(height: 24)
```

### การแก้ Theme
```dart
// core/themes/app_theme.dart
// แก้ไขที่ lightTheme หรือ darkTheme

// เพิ่มสีใหม่
// core/themes/app_colors.dart
static const Color newColor = Color(0xFF123456);
```

## 🔐 Authentication & Authorization

### Authentication Flow
```dart
// Sign In
context.read<AuthBloc>().add(SignInWithGoogleEvent());

// Sign Out
context.read<AuthBloc>().add(SignOutEvent());

// Check Auth Status
final isAuthenticated = context.read<AuthBloc>().state is Authenticated;
```

### Role-Based Access Control (RBAC)
```dart
// ตรวจสอบ Permission
PermissionGuard(
  permissionId: 'manage_products',
  child: YourWidget(),
  fallback: const Text('Access Denied'),
)

// ตรวจสอบ Role
if (user.isAdmin) {
  // Admin features
}

// เพิ่ม Permission ใหม่
// services/rbac/role_manager.dart
const Permission(
  id: 'new_permission',
  name: 'New Permission',
  description: 'Description',
  category: 'category',
)
```

## 🗄️ Database (Supabase)

### การเชื่อมต่อ API
```dart
// data/datasources/product_remote_data_source.dart
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final SupabaseClient supabaseClient;
  
  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final response = await supabaseClient
          .from('products')
          .select()
          .order('created_at', ascending: false);
          
      return (response as List)
          .map((e) => ProductModel.fromJson(e))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get products');
    }
  }
}
```

### Service Client (สำหรับข้าม RLS)
```dart
// ใช้เมื่อต้องการข้าม Row Level Security
SupabaseServiceClient().client
    .from('table')
    .select();
```

## 🧭 Navigation

### การ Navigate
```dart
// ไปหน้าใหม่
context.go('/products');

// ไปหน้าใหม่พร้อม parameter
context.go('/product/${product.id}');

// Push หน้าใหม่ (เก็บ stack)
context.push('/product-detail');

// กลับหน้าเดิม
context.pop();

// Replace หน้าปัจจุบัน
context.replace('/new-page');
```

### ป้องกันการเด้งกลับ
```dart
// ใช้ WillPopScope
WillPopScope(
  onWillPop: () async {
    // Return false เพื่อป้องกันการกลับ
    return false;
  },
  child: YourPage(),
)
```

## ⚡ Performance Optimization

### 1. ใช้ const constructor
```dart
const Text('Hello');
const SizedBox(height: 16);
```

### 2. ใช้ ListView.builder สำหรับ list ยาว
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

### 3. Cache data
```dart
class UserModel {
  static UserModel? _cachedUser;
  static DateTime? _cacheTimestamp;
  
  static bool _isCacheValid() {
    if (_cachedUser == null || _cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < Duration(minutes: 5);
  }
}
```

### 4. Lazy loading
```dart
// ใช้ FutureBuilder หรือ StreamBuilder
FutureBuilder<Data>(
  future: loadData(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return DataWidget(snapshot.data!);
    }
    return const CircularProgressIndicator();
  },
)
```

## 🎯 Code Style & Conventions

### Naming Conventions
```dart
// Classes: PascalCase
class ProductModel {}

// Variables/Functions: camelCase
final productName = 'iPhone';
void loadProducts() {}

// Constants: camelCase หรือ SCREAMING_SNAKE_CASE
const defaultTimeout = Duration(seconds: 30);
const API_KEY = 'xxx';

// Files: snake_case
product_model.dart
product_repository_impl.dart
```

### Import Order
```dart
// 1. Dart imports
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports
import 'package:flutter_bloc/flutter_bloc.dart';

// 4. Project imports (relative)
import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';
```

## 🧩 Custom Widgets

### สร้าง Reusable Widget
```dart
// widgets/custom_card.dart
class CustomCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onTap;
  
  const CustomCard({
    super.key,
    required this.title,
    required this.child,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.typography.h5),
              AppSpacing.verticalGapSm,
              child,
            ],
          ),
        ),
      ),
    );
  }
}
```

## 🚨 Error Handling

### ใน BLoC
```dart
try {
  final data = await repository.getData();
  emit(DataLoaded(data));
} on ServerException catch (e) {
  emit(DataError(e.message));
} catch (e) {
  emit(DataError('Unexpected error occurred'));
}
```

### แสดง Error UI
```dart
BlocBuilder<ProductBloc, ProductState>(
  builder: (context, state) {
    if (state is ProductError) {
      return ErrorWidget(
        message: state.message,
        onRetry: () {
          context.read<ProductBloc>().add(LoadProductsEvent());
        },
      );
    }
    // ...
  },
)
```

## 🔧 Debugging Tips

### 1. ใช้ Logger Service
```dart
LoggerService.info('Loading products', 'PRODUCT');
LoggerService.error('Failed to load', 'PRODUCT', error);
```

### 2. ตรวจสอบ State
```dart
// ใน BLoC
@override
void onChange(Change<ProductState> change) {
  super.onChange(change);
  LoggerService.debug('State change: ${change.currentState} → ${change.nextState}');
}
```

### 3. Network Monitoring
```dart
// Check connection
final isConnected = await NetworkInfo().isConnected;
```

## 📝 Best Practices

1. **แยก Logic ออกจาก UI** - ใช้ BLoC pattern
2. **ใช้ const ทุกที่ที่เป็นไปได้** - เพิ่ม performance
3. **Handle errors ทุกจุด** - ไม่ปล่อยให้แอพ crash
4. **Test edge cases** - null, empty list, network error
5. **ใช้ Dependency Injection** - ง่ายต่อการ test และ maintain
6. **เขียน documentation** - อธิบายส่วนที่ซับซ้อน
7. **Follow conventions** - ทำให้โค้ดอ่านง่าย
8. **Optimize imports** - ลบ import ที่ไม่ใช้
9. **Use type safety** - ระบุ type ชัดเจน
10. **Keep widgets small** - แยก widget ย่อยๆ

## 🚀 Quick Start Checklist

เมื่อจะเพิ่มฟีเจอร์ใหม่:

- [ ] สร้างโครงสร้าง folder ตาม Clean Architecture
- [ ] สร้าง Entity ก่อน (domain layer)
- [ ] สร้าง Model extends Entity (data layer)
- [ ] สร้าง Repository interface (domain)
- [ ] Implement Repository (data)
- [ ] สร้าง Use Cases
- [ ] สร้าง BLoC (Events, States, Bloc)
- [ ] สร้าง UI (Page & Widgets)
- [ ] เพิ่ม DI registration
- [ ] เพิ่ม Route
- [ ] Test ทุก layer
- [ ] เพิ่ม Permission ถ้าต้องการ