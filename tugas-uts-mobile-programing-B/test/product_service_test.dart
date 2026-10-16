import 'dart:convert';

import 'package:flutter_application_3/services/product_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Matcher serviceError(String contains_) => throwsA(
      isA<ProductServiceException>()
          .having((e) => e.message, 'message', contains(contains_)),
    );

void main() {
  test('respons sukses: produk dan pagination terbaca, item rusak dilewati',
      () async {
    final service = ProductService(
      client: MockClient((_) async => jsonResponse({
            'ok': true,
            'code': 'PRODUCTS_LIST',
            'message': 'Products fetched',
            'data': {
              'products': [
                {
                  'product_id': 1,
                  'name': 'Produk A',
                  'currency': 'USD',
                  'price': 1.5,
                },
                {'product_id': 2}, // tanpa name -> dilewati
                'bukan objek', // bukan map -> dilewati
              ],
              'pagination': {
                'page': 1,
                'per_page': 50,
                'total': 234,
                'total_pages': 5,
              },
            },
          })),
    );

    final result = await service.fetchProducts();

    expect(result.products.length, 1);
    expect(result.products.first.name, 'Produk A');
    expect(result.skipped, 2);
    expect(result.pagination.total, 234);
    expect(result.pagination.totalPages, 5);
  });

  test('halaman 2 mengirim parameter page=2', () async {
    Uri? requested;
    final service = ProductService(
      client: MockClient((request) async {
        requested = request.url;
        return jsonResponse({
          'ok': true,
          'data': {'products': [], 'pagination': {}},
        });
      }),
    );

    await service.fetchProducts(page: 2);

    expect(requested?.queryParameters['page'], '2');
  });

  test('data kosong: daftar produk kosong tanpa error', () async {
    final service = ProductService(
      client: MockClient((_) async => jsonResponse({
            'ok': true,
            'data': {'products': [], 'pagination': {}},
          })),
    );

    final result = await service.fetchProducts();

    expect(result.products, isEmpty);
  });

  test('status HTTP 500 menghasilkan pesan error', () async {
    final service =
        ProductService(client: MockClient((_) async => http.Response('x', 500)));

    await expectLater(service.fetchProducts(), serviceError('500'));
  });

  test('ok=false dari API menghasilkan pesan error', () async {
    final service = ProductService(
      client: MockClient((_) async =>
          jsonResponse({'ok': false, 'message': 'Rate limited'})),
    );

    await expectLater(service.fetchProducts(), serviceError('API menolak'));
  });

  test('JSON tidak valid menghasilkan pesan error', () async {
    final service = ProductService(
      client: MockClient((_) async => http.Response('bukan json', 200)),
    );

    await expectLater(service.fetchProducts(), serviceError('bukan JSON'));
  });

  test('struktur tanpa field data menghasilkan pesan error', () async {
    final service = ProductService(
      client: MockClient((_) async => jsonResponse({'ok': true})),
    );

    await expectLater(service.fetchProducts(), serviceError('"data"'));
  });

  test('gagal koneksi menghasilkan pesan error', () async {
    final service = ProductService(
      client: MockClient((_) async => throw http.ClientException('putus')),
    );

    await expectLater(
        service.fetchProducts(), serviceError('Tidak dapat terhubung'));
  });
}