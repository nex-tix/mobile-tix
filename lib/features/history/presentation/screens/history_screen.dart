import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';

import '../../../../core/constants/ticket_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/i18n_helper.dart';
import '../../bloc/history_cubit.dart';
import '../../bloc/history_state.dart';
import '../../data/models/scan_record.dart';
import '../widgets/history_row.dart';
import '../widgets/history_skeleton.dart';

/// Screen 13: History All.
///
/// Fitur:
/// - Dropdown status: All / Valid / Rejected
/// - Dropdown urutan: Terbaru / Tamu terbanyak / Tanggal/jam terlama
/// - Dropdown gate (dinamis dari data yang sudah dimuat)
/// - Search bar untuk filter lokal (API riwayat tidak punya parameter `q`)
/// - Pull-to-refresh; infinite scroll otomatis dimatikan bila search/sort aktif
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

/// Pilihan status di dropdown filter riwayat.
enum _HistoryStatus { all, valid, rejected }

/// Opsi urutan daftar riwayat.
///
/// [newest] adalah urutan bawaan server (terbaru di atas). Dua opsi lainnya
/// disusun di sisi klien dari baris yang sudah dimuat.
enum _HistorySort { newest, mostGuests, oldest }

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  _HistoryStatus _status = _HistoryStatus.all;
  _HistorySort _sort = _HistorySort.newest;

  /// Hasil pencarian lokal — API riwayat tidak punya parameter `q`.
  String _query = '';

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
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels <= 320) {
      context.read<HistoryCubit>().loadMore();
    }
  }

  static HistoryFilter _filterFor(_HistoryStatus status) => switch (status) {
    _HistoryStatus.all => HistoryFilter.none,
    _HistoryStatus.valid => const HistoryFilter(status: TicketStatus.valid),
    _HistoryStatus.rejected => HistoryFilter.rejected,
  };

  void _selectStatus(_HistoryStatus status) {
    if (_status == status) return;
    setState(() => _status = status);
    context.read<HistoryCubit>().applyFilter(_filterFor(status));
  }

  void _selectSort(_HistorySort sort) {
    if (_sort == sort) return;
    setState(() => _sort = sort);
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
  }

  /// Terapkan pencarian lalu urutan di atas baris yang sudah dimuat.
  ///
  /// Filter status/gate/tanggal tetap berlaku di server; dua langkah ini
  /// murni sisi klien sehingga tidak memicu request baru.
  List<ScanRecord> _apply(List<ScanRecord> records) {
    final query = _query.trim().toLowerCase();
    final List<ScanRecord> filtered;
    if (query.isEmpty) {
      filtered = List<ScanRecord>.of(records);
    } else {
      filtered = records.where((record) {
        return record.ticketCode.toLowerCase().contains(query) ||
            (record.visitorName?.toLowerCase().contains(query) ?? false) ||
            (record.checkpoint?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    final sorted = List<ScanRecord>.of(filtered);
    switch (_sort) {
      case _HistorySort.newest:
        // Urutan server sudah terbaru di atas — tidak disentuh.
        break;
      case _HistorySort.oldest:
        sorted.sort((a, b) => a.scannedAt.compareTo(b.scannedAt));
        break;
      case _HistorySort.mostGuests:
        sorted.sort((a, b) => b.visitorCount.compareTo(a.visitorCount));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.ground,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            final records = _apply(state.records);
            final count = state.totalItems > 0
                ? state.totalItems
                : state.records.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(count: count),
                _Controls(
                  selectedStatus: _status,
                  onSelectStatus: _selectStatus,
                  selectedSort: _sort,
                  onSelectSort: _selectSort,
                  searchController: _searchController,
                  onQueryChanged: _onQueryChanged,
                  state: state,
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
    if (records.isEmpty && state.isLoading) {
      return const HistorySkeleton();
    }

    if (records.isEmpty) {
      final bool searching = _query.trim().isNotEmpty;
      final message = state is HistoryFailure && !searching
          ? state.message
          : context.trSafe('history.empty', 'Tidak ada data tiket');
      return RefreshIndicator(
        onRefresh: () => context.read<HistoryCubit>().refresh(),
        color: context.colors.primary,
        backgroundColor: context.colors.surface,
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

    // Search/sort klien menonaktifkan infinite scroll agar posisi scroll
    // tidak melompat tengah daftar.
    final manualMode = _query.trim().isNotEmpty || _sort != _HistorySort.newest;
    final showLoadingMore = state.hasMore && state.loadingMore;
    final itemCount = records.length + (showLoadingMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () => context.read<HistoryCubit>().refresh(),
      color: context.colors.primary,
      backgroundColor: context.colors.surface,
      child: ListView.builder(
        controller: _scrollController,
        physics: manualMode ? const AlwaysScrollableScrollPhysics() : null,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= records.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final record = records[index];
          return HistoryRow(record: record);
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.trSafe('history.title', 'Riwayat'),
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.colors.ink,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            context.trSafe(
              'history.scansCount',
              '$count scans',
              namedArgs: {'count': '$count'},
            ),
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13,
              color: context.colors.inkMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris kontrol: search bar penuh lebar + tiga dropdown dalam satu baris.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.selectedStatus,
    required this.onSelectStatus,
    required this.selectedSort,
    required this.onSelectSort,
    required this.searchController,
    required this.onQueryChanged,
    required this.state,
  });

  final _HistoryStatus selectedStatus;
  final ValueChanged<_HistoryStatus> onSelectStatus;
  final _HistorySort selectedSort;
  final ValueChanged<_HistorySort> onSelectSort;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final HistoryState state;

  String _statusLabel(BuildContext context, _HistoryStatus status) =>
      switch (status) {
        _HistoryStatus.all => context.trSafe('history.all', 'All'),
        _HistoryStatus.valid => context.trSafe('history.valid', 'Valid'),
        _HistoryStatus.rejected => context.trSafe(
          'history.rejected',
          'Rejected',
        ),
      };

  String _sortLabel(BuildContext context, _HistorySort sort) => switch (sort) {
    _HistorySort.newest => context.trSafe('history.sortNewest', 'Terbaru'),
    _HistorySort.mostGuests => context.trSafe(
      'history.sortMostGuests',
      'Tamu terbanyak',
    ),
    _HistorySort.oldest => context.trSafe(
      'history.sortOldest',
      'Tanggal/jam terlama',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        children: [
          // Search bar — pencarian lokal atas baris yang sudah dimuat.
          TextField(
            key: const Key('history-search-field'),
            controller: searchController,
            onChanged: onQueryChanged,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13.5,
              color: colors.ink,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: context.trSafe(
                'history.searchHint',
                'Cari ID atau nama tamu',
              ),
              hintStyle: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13.5,
                color: colors.inkMuted,
              ),
              prefixIcon: Icon(
                AppIcons.search,
                size: 19,
                color: colors.inkMuted,
              ),
              suffixIcon: IconButton(
                icon: Icon(AppIcons.close, size: 18, color: colors.inkMuted),
                splashRadius: 18,
                onPressed: () {
                  searchController.clear();
                  onQueryChanged('');
                },
              ),
              filled: true,
              fillColor: colors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: colors.outline.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: colors.outline.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: colors.primary, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Dropdown status: All / Valid / Rejected.
              Expanded(
                child: _DropdownChip<_HistoryStatus>(
                  key: const Key('history-status-filter'),
                  value: selectedStatus,
                  items: _HistoryStatus.values,
                  labelOf: (value) => _statusLabel(context, value),
                  onSelect: onSelectStatus,
                  isSelected: true,
                  showArrow: false,
                ),
              ),
              const SizedBox(width: 8),
              // Dropdown urutan: terbaru / tamu terbanyak / terlama.
              Expanded(
                child: _DropdownChip<_HistorySort>(
                  key: const Key('history-sort-filter'),
                  value: selectedSort,
                  items: _HistorySort.values,
                  labelOf: (value) => _sortLabel(context, value),
                  onSelect: onSelectSort,
                  isSelected: selectedSort != _HistorySort.newest,
                  showArrow: true,
                ),
              ),
              const SizedBox(width: 8),
              // Dropdown gate — nilainya dari checkpoint baris yang dimuat.
              Expanded(
                child: Builder(
                  builder: (context) {
                    final gates = <String>{
                      for (final record in state.records)
                        if (record.checkpoint != null) record.checkpoint!,
                    }.toList()..sort();
                    final selected = state.filter.checkpoint ?? 'all';
                    return _DropdownChip<String>(
                      key: const Key('history-gate-filter'),
                      value: selected,
                      items: ['all', ...gates],
                      labelOf: (value) => value == 'all'
                          ? context.trSafe('history.allGates', 'Semua gate')
                          : context.trSafe(
                              'history.gateNamed',
                              'Gate: {name}',
                              namedArgs: {'name': value},
                            ),
                      onSelect: (value) =>
                          context.read<HistoryCubit>().applyFilter(
                            state.filter.withCheckpoint(
                              value == 'all' ? null : value,
                            ),
                          ),
                      isSelected: selected != 'all',
                      showArrow: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chip dropdown: tombol dengan bentuk pill, opsi muncul sebagai bottom sheet.
class _DropdownChip<T> extends StatelessWidget {
  const _DropdownChip({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onSelect,
    this.isSelected = false,
    this.showArrow = true,
  });

  final T value;
  final List<T> items;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelect;
  final bool isSelected;
  final bool showArrow;

  static const _radius = 24.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: colors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in items)
                  ListTile(
                    dense: true,
                    title: Text(
                      labelOf(option),
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        fontWeight: option == value
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: option == value ? colors.primary : colors.ink,
                      ),
                    ),
                    trailing: option == value
                        ? Icon(AppIcons.check, size: 18, color: colors.primary)
                        : null,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onSelect(option);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryTint : colors.surface,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outline.withValues(alpha: 0.7),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  labelOf(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? colors.primary : colors.ink,
                  ),
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: 4),
                Icon(
                  AppIcons.arrowDown,
                  size: 13,
                  color: isSelected ? colors.primary : colors.inkMuted,
                ),
              ],
            ],
          ),
        ),
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
          Icon(
            AppIcons.historyToggleOff,
            size: 48,
            color: context.colors.inkMuted,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.colors.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.colors.outline),
              foregroundColor: context.colors.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(context.trSafe('common.retry', 'Muat ulang')),
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
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.cancelledTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.cancelled),
      ),
      child: Row(
        children: [
          Icon(AppIcons.error, size: 18, color: context.colors.cancelled),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12.5,
                color: context.colors.cancelled,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: context.colors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(44, 36),
            ),
            child: Text(context.trSafe('common.retry', 'COBA').toUpperCase()),
          ),
        ],
      ),
    );
  }
}
