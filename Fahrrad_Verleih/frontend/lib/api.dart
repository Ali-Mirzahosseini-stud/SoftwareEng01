import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BikeApi {
  BikeApi({String? baseUrl}) : baseUrl = baseUrl ?? 'http://localhost:8080';

  final String baseUrl;

  Future<dynamic> _request(String path, {String method = 'GET', Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = method == 'POST'
        ? await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
        : await http.get(uri);
    final data = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data is Map ? data['error']?.toString() ?? 'Serverfehler' : 'Serverfehler');
    }
    return data;
  }

  Future<Dashboard> getDashboard() async =>
      Dashboard.fromJson(await _request('/api/dashboard') as Map<String, dynamic>);

  Future<List<RentalItem>> getItems() async => (await _request('/api/items') as List)
      .map((item) => RentalItem.fromJson(item as Map<String, dynamic>))
      .toList();

  Future<List<Customer>> getCustomers() async => (await _request('/api/customers/list') as List)
      .map((item) => Customer.fromJson(item as Map<String, dynamic>))
      .toList();

  Future<List<Rental>> getRentals() async => (await _request('/api/rentals') as List)
      .map((item) => Rental.fromJson(item as Map<String, dynamic>))
      .toList();

  Future<Customer> createCustomer({
    required String name,
    required String documentType,
    required String documentNumber,
    String? fileName,
    Uint8List? fileBytes,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/customers'));
    request.fields.addAll({
      'name': name,
      'document_type': documentType,
      'document_number': documentNumber,
    });
    if (fileName != null && fileBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('document', fileBytes, filename: fileName));
    }
    final response = await request.send();
    final data = jsonDecode(await response.stream.bytesToString());
    if (response.statusCode != 201) {
      throw ApiException(data['error']?.toString() ?? 'Kunde konnte nicht angelegt werden');
    }
    return Customer.fromJson(data as Map<String, dynamic>);
  }

  Future<Rental> startRental({
    required String itemId,
    required String customerId,
    required DateTime startedAt,
    double? plannedDurationHours,
  }) async {
    final data = await _request('/api/rentals/start', method: 'POST', body: {
      'item_id': itemId,
      'customer_id': customerId,
      'started_at': startedAt.toUtc().toIso8601String(),
      if (plannedDurationHours != null) 'planned_duration_hours': plannedDurationHours,
    });
    return Rental.fromJson(data as Map<String, dynamic>);
  }

  Future<CompletedRental> endRental({required String rentalId, required DateTime endedAt}) async {
    final data = await _request('/api/rentals/end', method: 'POST', body: {
      'rental_id': rentalId,
      'ended_at': endedAt.toUtc().toIso8601String(),
    });
    return CompletedRental.fromJson(data as Map<String, dynamic>);
  }
}
