class Dashboard {
  const Dashboard({
    required this.availableItems,
    required this.rentedItems,
    required this.totalItems,
    required this.registeredCustomers,
  });

  final int availableItems;
  final int rentedItems;
  final int totalItems;
  final int registeredCustomers;

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
        availableItems: json['available_items'] as int? ?? 0,
        rentedItems: json['rented_items'] as int? ?? 0,
        totalItems: json['total_items'] as int? ?? 0,
        registeredCustomers: json['registered_customers'] as int? ?? 0,
      );
}

class RentalItem {
  const RentalItem({
    required this.id,
    required this.name,
    required this.type,
    required this.hourlyRate,
    required this.isRented,
  });

  final String id;
  final String name;
  final String type;
  final double hourlyRate;
  final bool isRented;

  factory RentalItem.fromJson(Map<String, dynamic> json) => RentalItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
        hourlyRate: (json['hourly_rate'] as num? ?? 0).toDouble(),
        isRented: json['is_rented'] as bool? ?? false,
      );
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.documentType,
    required this.documentNumber,
  });

  final String id;
  final String name;
  final String documentType;
  final String documentNumber;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        documentType: json['document_type'] as String? ?? '',
        documentNumber: json['document_number'] as String? ?? '',
      );
}

class Rental {
  const Rental(
      {required this.id,
      required this.itemId,
      required this.customerId,
      required this.plannedDurationHours,
      required this.endedAt});

  final String id;
  final String itemId;
  final String customerId;
  final double? plannedDurationHours;
  final DateTime? endedAt;

  factory Rental.fromJson(Map<String, dynamic> json) => Rental(
        id: json['id'] as String? ?? '',
        itemId: json['item_id'] as String? ?? '',
        customerId: json['customer_id'] as String? ?? '',
        plannedDurationHours:
            (json['planned_duration_hours'] as num?)?.toDouble(),
        endedAt: json['ended_at'] == null
            ? null
            : DateTime.tryParse(json['ended_at'] as String),
      );
}

class CompletedRental {
  const CompletedRental({required this.billedHours, required this.totalPrice});

  final int billedHours;
  final double totalPrice;

  factory CompletedRental.fromJson(Map<String, dynamic> json) =>
      CompletedRental(
        billedHours: json['billed_hours'] as int? ?? 0,
        totalPrice: (json['total_price'] as num? ?? 0).toDouble(),
      );
}
