/// Persyaratan input untuk memesan sebuah produk (informasi saja).
class OrderRequirements {
  final String profile;
  final String label;
  final String description;
  final bool requiresUserId;
  final bool requiresServerId;
  final List<String> fieldLabels;

  const OrderRequirements({
    required this.profile,
    required this.label,
    required this.description,
    required this.requiresUserId,
    required this.requiresServerId,
    required this.fieldLabels,
  });

  factory OrderRequirements.fromJson(Map<String, dynamic> json) {
    final fields = json['fields'];
    return OrderRequirements(
      profile: _asString(json['profile']) ?? 'unknown',
      label: _asString(json['label']) ?? '-',
      description: _asString(json['description']) ?? '',
      requiresUserId: _asBool(json['requires_user_id']),
      requiresServerId: _asBool(json['requires_server_id']),
      fieldLabels: fields is List
          ? fields
              .whereType<Map>()
              .map((f) => _asString(f['label']))
              .whereType<String>()
              .toList()
          : const [],
    );
  }
}

/// Satu produk dari endpoint /api/v1/products.
class Product {
  final int id;
  final String type;
  final String name;
  final String currency;
  final bool h2hOnly;
  final double? price;
  final double? regularPrice;
  final double? salePrice;
  final bool onSale;
  final double? minPrice;
  final double? maxPrice;
  final bool hasVariations;
  final String? imageUrl;
  final OrderRequirements? orderRequirements;

  const Product({
    required this.id,
    required this.type,
    required this.name,
    required this.currency,
    required this.h2hOnly,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    required this.minPrice,
    required this.maxPrice,
    required this.hasVariations,
    required this.imageUrl,
    required this.orderRequirements,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['product_id']);
    final name = _asString(json['name']);
    if (id == null || name == null) {
      throw const FormatException('Produk tidak memiliki product_id atau name');
    }

    final req = json['order_requirements'];

    return Product(
      id: id,
      type: _asString(json['type']) ?? '-',
      name: name,
      currency: _asString(json['currency']) ?? '',
      h2hOnly: _asBool(json['h2h_only']),
      price: _asDouble(json['price']),
      regularPrice: _asDouble(json['regular_price']),
      salePrice: _asDouble(json['sale_price']),
      onSale: _asBool(json['on_sale']),
      minPrice: _asDouble(json['min_price']),
      maxPrice: _asDouble(json['max_price']),
      hasVariations: _asBool(json['has_variations']),
      imageUrl: _asString(json['image']),
      orderRequirements:
          req is Map<String, dynamic> ? OrderRequirements.fromJson(req) : null,
    );
  }

  bool get hasImage => imageUrl != null;

  /// Teks harga untuk ditampilkan. Mata uang diambil dari API, tanpa konversi.
  String get priceLabel {
    final min = minPrice;
    final max = maxPrice;
    if (min != null && max != null && min != max) {
      return _withCurrency('${_formatAmount(min)} – ${_formatAmount(max)}');
    }

    final sale = salePrice;
    final double? value =
        (onSale && sale != null && sale > 0) ? sale : (price ?? min);
    if (value == null) return 'Harga tidak tersedia';
    return _withCurrency(_formatAmount(value));
  }

  String _withCurrency(String amount) =>
      currency.isEmpty ? amount : '$amount $currency';
}

class Pagination {
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  const Pagination({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const Pagination(page: 1, perPage: 0, total: 0, totalPages: 1);
    }
    return Pagination(
      page: _asInt(json['page']) ?? 1,
      perPage: _asInt(json['per_page']) ?? 0,
      total: _asInt(json['total']) ?? 0,
      totalPages: _asInt(json['total_pages']) ?? 1,
    );
  }
}

/// Hasil satu kali permintaan: daftar produk + info pagination.
class ProductPage {
  final List<Product> products;
  final Pagination pagination;

  /// Jumlah item yang dilewati karena datanya tidak valid.
  final int skipped;

  const ProductPage({
    required this.products,
    required this.pagination,
    this.skipped = 0,
  });
}

// ---------- Fungsi bantu parsing (aman terhadap null / tipe berbeda) ----------

String? _asString(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool _asBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return false;
}

/// 2.1068000000000002 -> "2.1068", 5 -> "5.00", 0.095 -> "0.095"
String _formatAmount(double v) {
  var s = v.toStringAsFixed(4);
  while (s.endsWith('0') && s.length - s.indexOf('.') > 3) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}