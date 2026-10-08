import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';

import '../../../../core/constants/ticket_status.dart';
import '../../bloc/history_cubit.dart';
import '../../bloc/history_state.dart';
import '../../data/models/scan_record.dart';
import '../widgets/history_row.dart';

/// Screen 13: History All matching `newDesign/13._history_all/code.html`.
///
/// Seluruh isi layar berasal dari [HistoryCubit]: daftar, jumlah baris, halaman
/// berikutnya, dan kegagalan. Layanan hanya menggulir; tidak ada angka atau baris
/// yang dikarang di sini.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

/// Penyaring yang tersedia di layar.
enum _HistoryTab {
  all('All'),
  valid('Valid'),
  rejected('Rejected');

  const _HistoryTab(this.label);

  final String label;
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  _HistoryTab _tab = _HistoryTab.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HistoryCubit>().load();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Ambil halaman berikutnya sebelum petugas benar-benar mencapai dasar daftar,
  /// supaya gulirnya terasa tidak terputus. Cubit sendiri yang menjaga agar tidak
  /// ada dua permintaan berjalan sekaligus atau permintaan saat sudah habis.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels <= 320) {
      context.read<HistoryCubit>().loadMore();
    }
  }

  static HistoryFilter _filterFor(_HistoryTab tab) => switch (tab) {
    _HistoryTab.all => HistoryFilter.none,
    _HistoryTab.valid => const HistoryFilter(status: TicketStatus.valid),
    _HistoryTab.rejected => HistoryFilter.rejected,
  };

  void _selectTab(_HistoryTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    context.read<HistoryCubit>().applyFilter(_filterFor(tab));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A363B),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            final records = state.records;
            final count = state.totalItems > 0
                ? state.totalItems
                : records.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(count: count),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: _FilterTabs(
                    selected: _tab,
                    onSelect: _selectTab,
                  ),
                ),
                if (state is HistoryFailure && state.hasRecords)
                  _ErrorBanner(
                    message: state.message,
                    onRetry: () => context.read<HistoryCubit>().refresh(),
                  ),
                Expanded(child: _body(state, records)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(HistoryState state, List<ScanRecord> records) {
    // Pengambilan pertama belum selesai dan belum ada apa pun untuk digambar.
    if (records.isEmpty && state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFFCF4647),
        ),
      );
    }

    if (records.isEmpty) {
      final message = state is HistoryFailure
          ? state.message
          : 'Tidak ada data tiket';
      return RefreshIndicator(
        onRefresh: () => context.read<HistoryCubit>().refresh(),
        color: const Color(0xFFCF4647),
        backgroundColor: const Color(0xFF212B2F),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _EmptyView(
              message: message,
              onRetry: () => context.read<HistoryCubit>().refresh(),
            ),
          ],
        ),
      );
    }

    final itemCount = records.length + (state.hasMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () => context.read<HistoryCubit>().refresh(),
      color: const Color(0xFFCF4647),
      backgroundColor: const Color(0xFF212B2F),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 110),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= records.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFFCF4647),
                  ),
                ),
              ),
            );
          }
          return HistoryRow(record: records[index]);
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'History',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF8F6F6),
              letterSpacing: -0.2,
            ),
          ),
          Text(
            '$count scans',
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFFA3B1B7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onSelect});

  final _HistoryTab selected;
  final ValueChanged<_HistoryTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E272B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334147)),
      ),
      child: Row(
        children: [
          for (final tab in _HistoryTab.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected == tab
                        ? const Color(0xFFCF4647)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tab.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected == tab
                          ? const Color(0xFFF8F6F6)
                          : const Color(0xFFA3B1B7),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Column(
        children: [
          const Icon(
            AppIcons.historyToggleOff,
            size: 48,
            color: Color(0xFF4B5E66),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFA3B1B7),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF3E4E55)),
              foregroundColor: const Color(0xFFF8F6F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Muat ulang'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x26CF4647),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x4DCF4647)),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.error, size: 18, color: Color(0xFFFFB3AF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12.5,
                color: Color(0xFFFFB3AF),
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF8F6F6),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(44, 36),
            ),
            child: const Text('COBA'),
          ),
        ],
      ),
    );
  }
}
