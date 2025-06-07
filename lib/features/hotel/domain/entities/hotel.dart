// lib/features/hotel_booking/domain/entities/hotel.dart
import 'package:equatable/equatable.dart';

class Hotel extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double rating;
  final String imageUrl;

  const Hotel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.rating,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [id, name, description, price, rating, imageUrl];
}
