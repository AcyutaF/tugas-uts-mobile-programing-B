import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductServiceException implements Exception {
  final String message;
  const ProductServiceException(this.message);

  @override
  String toString() => message;
}

class ProductService {
  ProductService({http.Client? client}) : _client = client ?? http.Client();

  static const String endpoint =
      'https://distribution.liogames.com/api/v1/products';
  static const Duration _timeout = Duration(seconds: 20);

  final http.Client _client;

  /// Mengambil satu halaman produk. Halaman 1 dipanggil tanpa parameter.
  Future<ProductPage> fetchProducts({int page = 1}) async {
    final base = Uri.parse(endpoint);
    final uri =
        page > 1 ? base.replace(queryParameters: {'page': '$page'}) : base;

    final response = await _get(uri);

    if (response.statusCode != 200) {
      throw ProductServiceException(
        'Server mengembalikan status HTTP ${response.statusCode}.',
      );
    }

    final decoded = _decode(response);

    if (decoded is! Map<String, dynamic>) {
      throw const ProductServiceException(
        'Format respons tidak sesuai: root bukan objek JSON.',
      );
    }
    if (decoded['ok'] != true) {
      final info = decoded['message'] ?? decoded['code'] ?? 'tanpa pesan';
      throw ProductServiceException('API menolak permintaan: $info');
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const ProductServiceException(
        'Format respons tidak sesuai: field "data" tidak ditemukan.',
      );
    }

    final rawProducts = data['products'];
    if (rawProducts is! List) {
      throw const ProductServiceException(
        'Format respons tidak sesuai: field "products" bukan daftar.',
      );
    }

    final products = <Product>[];
    var skipped = 0;
    for (final item in rawProducts) {
      if (item is Map<String, dynamic>) {
        try {
          products.add(Product.fromJson(item));
          continue;
        } on FormatException {
          // jatuh ke penghitungan skipped di bawah
        }
      }
      skipped++;
    }

    final rawPagination = data['pagination'];
    final pagination = Pagination.fromJson(
      rawPagination is Map<String, dynamic> ? rawPagination : null,
    );

    return ProductPage(
      products: products,
      pagination: pagination,
      skipped: skipped,
    );
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);
    } on TimeoutException {
      throw const ProductServiceException(
        'Permintaan melebihi batas waktu (20 detik). Periksa koneksi internet.',
      );
    } on http.ClientException catch (e) {
      throw ProductServiceException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet. (${e.message})',
      );
    }
  }

  dynamic _decode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ProductServiceException(
        'Respons server bukan JSON yang valid.',
      );
    }
  }

  void dispose() => _client.close();
}