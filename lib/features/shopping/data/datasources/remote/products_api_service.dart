// lib/features/shopping/data/datasources/remote/products_api_service.dart
import 'package:dio/dio.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../models/product_model.dart';

class ProductsApiService {
  final Dio dio;

  ProductsApiService({required this.dio});

  Future<List<ProductModel>> getProducts() async {
    try {
      // Placeholder implementation
      return [];
    } catch (e) {
      throw ServerException('Failed to get products: ${e.toString()}');
    }
  }
}
