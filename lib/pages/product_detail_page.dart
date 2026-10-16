import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  void _showSimulation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulasi'),
        content: Text(
          'Anda memilih "${product.name}".\n\n'
          'Ini hanya simulasi untuk keperluan tugas UTS. Tidak ada transaksi, '
          'pembayaran, atau top-up sungguhan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final req = product.orderRequirements;
    final min = product.minPrice;
    final max = product.maxPrice;
    final isRange = min != null && max != null && min != max;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 200,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ProductImage(url: product.imageUrl),
          ),
          const SizedBox(height: 16),
          Text(
            product.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            product.priceLabel,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isRange)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Harga ditampilkan sebagai rentang (terendah – tertinggi).',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          if (product.h2hOnly) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.gold),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Produk ini ditandai khusus reseller (H2H) oleh API. '
                      'Aplikasi ini hanya menampilkan informasinya dan tidak '
                      'menyediakan pemilihan produk ini.',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Informasi Produk',
            rows: [
              _InfoRow('ID Produk', '${product.id}'),
              _InfoRow('Tipe', product.type),
              _InfoRow('Mata uang', product.currency.isEmpty ? '-' : product.currency),
              _InfoRow('Varian', product.hasVariations ? 'Memiliki varian' : 'Tanpa varian'),
              _InfoRow('Akses', product.h2hOnly ? 'Khusus reseller (H2H)' : 'Umum'),
            ],
          ),
          if (req != null) ...[
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Data yang Dibutuhkan',
              rows: [
                _InfoRow('Jenis', req.label),
                if (req.description.isNotEmpty)
                  _InfoRow('Keterangan', req.description),
                _InfoRow(
                  'Isian',
                  req.fieldLabels.isEmpty ? 'Tidak ada' : req.fieldLabels.join(', '),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: product.h2hOnly ? null : () => _showSimulation(context),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              product.h2hOnly ? 'Tidak tersedia di aplikasi ini' : 'Pilih Produk (Simulasi)',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'FaaStore adalah proyek akademik. Tidak ada transaksi atau '
            'pembayaran sungguhan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      row.label,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  Expanded(child: Text(row.value)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}