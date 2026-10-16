import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = ProductService();
  final _searchController = TextEditingController();
  final List<Product> _products = [];

  Pagination? _pagination;
  int _loadedPage = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _moreError;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  bool get _hasMore {
    final p = _pagination;
    return p != null && _loadedPage < p.totalPages;
  }

  List<Product> get _filtered {
    if (_query.isEmpty) return _products;
    final q = _query.toLowerCase();
    return _products.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  String _messageOf(Object e) => e is ProductServiceException
      ? e.message
      : 'Terjadi kesalahan tidak terduga: $e';

  Future<void> _loadFirstPage({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final page = await _service.fetchProducts(page: 1);
      if (!mounted) return;
      setState(() {
        _products
          ..clear()
          ..addAll(page.products);
        _pagination = page.pagination;
        _loadedPage = 1;
        _error = null;
        _moreError = null;
      });
    } catch (e) {
      if (!mounted) return;
      final message = _messageOf(e);
      if (_products.isEmpty) {
        setState(() => _error = message);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui: $message')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final next = _loadedPage + 1;
      final page = await _service.fetchProducts(page: next);
      if (!mounted) return;
      final existing = _products.map((p) => p.id).toSet();
      setState(() {
        _products.addAll(page.products.where((p) => !existing.contains(p.id)));
        _pagination = page.pagination;
        _loadedPage = next;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _moreError = _messageOf(e));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _openDetail(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FaaStore')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim()),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.gold),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat produk...'),
          ],
        ),
      );
    }

    if (_error != null && _products.isEmpty) {
      return _MessageView(
        icon: Icons.cloud_off_rounded,
        title: 'Gagal memuat data',
        message: _error!,
        actionLabel: 'Coba lagi',
        onAction: _loadFirstPage,
      );
    }

    if (_products.isEmpty) {
      return _MessageView(
        icon: Icons.inventory_2_outlined,
        title: 'Belum ada produk',
        message: 'API tidak mengembalikan produk apa pun.',
        actionLabel: 'Muat ulang',
        onAction: _loadFirstPage,
      );
    }

    final items = _filtered;
    if (items.isEmpty) {
      return _MessageView(
        icon: Icons.search_off_rounded,
        title: 'Produk tidak ditemukan',
        message: 'Tidak ada produk bernama "$_query" di antara '
            '${_products.length} produk yang sudah dimuat.',
        actionLabel: _hasMore ? 'Muat produk lainnya' : null,
        onAction: _hasMore ? _loadMore : null,
      );
    }

    final total = _pagination?.total ?? _products.length;
    final summary = _query.isEmpty
        ? 'Produk dimuat: ${_products.length} dari $total'
        : 'Ditemukan ${items.length} dari ${_products.length} produk yang '
            'dimuat (total katalog: $total)';

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () => _loadFirstPage(showSpinner: false),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                summary,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 260,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => ProductCard(
                  product: items[i],
                  onTap: () => _openDetail(items[i]),
                ),
                childCount: items.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildFooter()),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final total = _pagination?.total ?? _products.length;
    Widget child;

    if (_loadingMore) {
      child = const Center(child: CircularProgressIndicator());
    } else if (_moreError != null) {
      child = Column(
        children: [
          Text(
            _moreError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _loadMore, child: const Text('Coba lagi')),
        ],
      );
    } else if (_hasMore) {
      child = Center(
        child: OutlinedButton(
          onPressed: _loadMore,
          child: Text('Muat lebih banyak (${_products.length} / $total)'),
        ),
      );
    } else {
      child = const Center(
        child: Text(
          'Semua produk sudah dimuat',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      );
    }

    return Padding(padding: const EdgeInsets.all(20), child: child);
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.gold),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}