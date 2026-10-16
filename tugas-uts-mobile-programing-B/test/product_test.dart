import 'package:flutter_application_3/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product.fromJson', () {
    test('produk umum dengan rentang harga dan input User ID', () {
      // Meniru struktur "Racing Master (LATAM)" dari API.
      final product = Product.fromJson({
        'product_id': 539837,
        'type': 'variable',
        'name': 'Racing Master (LATAM)',
        'currency': 'USD',
        'h2h_only': false,
        'price': 0.286,
        'regular_price': 0,
        'sale_price': 0,
        'on_sale': false,
        'min_price': 0.29,
        'max_price': 51.32,
        'has_variations': true,
        'image': 'https://example.com/racing.jpg',
        'order_requirements': {
          'profile': 'user_id_exact',
          'label': 'User ID',
          'description': 'Requires User ID.',
          'requires_user_id': true,
          'requires_server_id': false,
          'fields': [
            {'key': 'user_id', 'label': 'User ID'},
          ],
        },
      });

      expect(product.id, 539837);
      expect(product.h2hOnly, false);
      expect(product.priceLabel, '0.29 – 51.32 USD');
      expect(product.hasImage, true);
      expect(product.orderRequirements?.requiresUserId, true);
      expect(product.orderRequirements?.fieldLabels, ['User ID']);
    });

    test('produk H2H dengan harga tunggal, desimal panjang dibulatkan', () {
      // Meniru "Steam Wallet (TR)": min_price == max_price.
      final product = Product.fromJson({
        'product_id': 540468,
        'name': 'Steam Wallet (TR)',
        'currency': 'USD',
        'h2h_only': true,
        'price': 4.8759999999999994,
        'regular_price': null,
        'sale_price': null,
        'on_sale': false,
        'min_price': 4.8759999999999994,
        'max_price': 4.8759999999999994,
      });

      expect(product.h2hOnly, true);
      expect(product.priceLabel, '4.876 USD');
    });

    test('harga bulat tampil dengan dua desimal', () {
      final product = Product.fromJson({
        'product_id': 539862,
        'name': 'Riot Access Code (LATAM)',
        'currency': 'USD',
        'price': 5,
        'min_price': 5,
        'max_price': 5,
      });

      expect(product.priceLabel, '5.00 USD');
    });

    test('field opsional kosong tidak membuat parsing gagal', () {
      final product = Product.fromJson({
        'product_id': 1,
        'name': 'Produk Tanpa Harga',
      });

      expect(product.hasImage, false);
      expect(product.priceLabel, 'Harga tidak tersedia');
      expect(product.orderRequirements, isNull);
    });

    test('produk tanpa name dianggap tidak valid', () {
      expect(
        () => Product.fromJson({'product_id': 1}),
        throwsFormatException,
      );
    });
  });
}