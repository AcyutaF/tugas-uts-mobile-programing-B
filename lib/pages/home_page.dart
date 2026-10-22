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

  /// Future untuk halaman 1. Dibaca oleh FutureBuilder.
  late Future<ProductPage> _firstPage;

  /// Produk dari halaman 2 dan seterusnya ("Muat lebih banyak").
  final List<Product> _morePages = [];
  Pagination? _pagination;
  int _loadedPage = 1;
  bool _loadingMore = false;
  String? _moreError;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _firstPage = _service.fetchProducts(page: 1);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  String _messageOf(Object e) => e is ProductServiceException
      ? e.message
      : 'Terjadi kesalahan tidak terduga: $e';

  List<Product> _filter(List<Product> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  /// Dipakai tombol "Coba lagi": membuat Future baru untuk FutureBuilder.
  void _retry() {
    setState(() {
      _morePages.clear();
      _pagination = null;
      _loadedPage = 1;
      _moreError = null;
      _firstPage = _service.fetchProducts(page: 1);
    });
  }

  /// Dipakai tarik-untuk-segarkan.
  Future<void> _refresh() async {
    try {
      final page = await _service.fetchProducts(page: 1);
      if (!mounted) return;
      setState(() {
        _firstPage = Future.value(page);
        _morePages.clear();
        _pagination = page.pagination;
        _loadedPage = 1;
        _moreError = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui: ${_messageOf(e)}')),
      );
    }
  }

  Future<void> _loadMore(ProductPage first) async {
    if (_loadingMore) return;
    final pagination = _pagination ?? first.pagination;
    if (_loadedPage >= pagination.totalPages) return;

    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final next = _loadedPage + 1;
      final page = await _service.fetchProducts(page: next);
      if (!mounted) return;
      final existing = <int>{
        ...first.products.map((p) => p.id),
        ..._morePages.map((p) => p.id),
      };
      setState(() {
        _morePages.addAll(page.products.where((p) => !existing.contains(p.id)));
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

  /// FutureBuilder menangani tiga kondisi: loading, error, dan success.
  Widget _buildBody() {
    return FutureBuilder<ProductPage>(
      future: _firstPage,
      builder: (context, snapshot) {
        // 1. LOADING
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
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

        // 2. ERROR
        if (snapshot.hasError) {
          return _MessageView(
            icon: Icons.cloud_off_rounded,
            title: 'Gagal memuat data',
            message: _messageOf(snapshot.error!),
            actionLabel: 'Coba lagi',
            onAction: _retry,
          );
        }

        // 3. SUCCESS
        final first = snapshot.data;
        if (first == null) return const SizedBox.shrink();
        return _buildCatalog(first);
      },
    );
  }

  Widget _buildCatalog(ProductPage first) {
    final all = [...first.products, ..._morePages];

    if (all.isEmpty) {
      return _MessageView(
        icon: Icons.inventory_2_outlined,
        title: 'Belum ada produk',
        message: 'API tidak mengembalikan produk apa pun.',
        actionLabel: 'Muat ulang',
        onAction: _retry,
      );
    }

    final items = _filter(all);
    final pagination = _pagination ?? first.pagination;
    final hasMore = _loadedPage < pagination.totalPages;
    final total = pagination.total > 0 ? pagination.total : all.length;

    if (items.isEmpty) {
      return _MessageView(
        icon: Icons.search_off_rounded,
        title: 'Produk tidak ditemukan',
        message: 'Tidak ada produk bernama "$_query" di antara '
            '${all.length} produk yang sudah dimuat.',
        actionLabel: hasMore ? 'Muat produk lainnya' : null,
        onAction: hasMore ? () => _loadMore(first) : null,
      );
    }

    final summary = _query.isEmpty
        ? 'Produk dimuat: ${all.length} dari $total'
        : 'Ditemukan ${items.length} dari ${all.length} produk yang '
            'dimuat (total katalog: $total)';

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: _refresh,
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
          SliverToBoxAdapter(
            child: _buildFooter(first, hasMore, total, all.length),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ProductPage first, bool hasMore, int total, int loaded) {
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
          OutlinedButton(
            onPressed: () => _loadMore(first),
            child: const Text('Coba lagi'),
          ),
        ],
      );
    } else if (hasMore) {
      child = Center(
        child: OutlinedButton(
          onPressed: () => _loadMore(first),
          child: Text('Muat lebih banyak ($loaded / $total)'),
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
