import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/demo_connectivity.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/data/dao/offline_queue_dao.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/i18n_helper.dart';
import '../../../auth/logic/session_state.dart';
import '../../../../core/ui/widgets/app_snackbar.dart';
import '../../../../shared/widgets/inline_status.dart';
import '../../../scanner/bloc/scanner_cubit.dart';
import '../../../scanner/bloc/scanner_state.dart';
import '../../../scanner/data/models/queued_scan.dart';
import '../../bloc/dashboard_cubit.dart';
import '../../bloc/dashboard_state.dart';
import '../widgets/dashboard_skeleton.dart';

/// Screen 3: Dashboard (Today) matching `newDesign/3._dashboard_today/code.html`.
///
/// Angka di layar ini hanya berasal dari [DashboardCubit]. Layar tidak pernah
/// menampilkan nol sebagai pengganti "belum tahu": selama belum ada data ia
/// menunjukkan skeleton, dan saat gagal ia mengatakan gagal.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardCubit>().loadToday();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    final connectivity = context.watch<DemoConnectivity>();
    final staff = session.staff;
    final checkpoint = session.checkpoint;

    return Scaffold(
      backgroundColor: context.colors.ground,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => context.read<DashboardCubit>().refresh(),
              color: context.colors.primary,
              backgroundColor: context.colors.surface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  24,
                  12,
                  24,
                  140.0 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      initials: staff?.initials ?? '',
                      online: connectivity.online,
                      isChecking: connectivity.isChecking,
                      onRefresh: () async {
                        final ok = await context
                            .read<DemoConnectivity>()
                            .checkConnection();
                        if (context.mounted) {
                          if (ok) {
                            AppSnackbar.success(
                              context,
                              context.trSafe(
                                'connectivity.connectedSuccess',
                                'Sinyal terhubung kembali (Online)',
                              ),
                            );
                          } else {
                            AppSnackbar.warning(
                              context,
                              context.trSafe(
                                'connectivity.stillOffline',
                                'Sinyal belum ditemukan, masih Mode Offline',
                              ),
                            );
                          }
                        }
                      },
                      onProfileTap: () =>
                          Navigator.of(context).pushNamed('/profile'),
                    ),
                    const SizedBox(height: 20),
                    _Greeting(
                      name: staff?.displayName ?? '',
                      gate: checkpoint?.gate ?? '',
                    ),
                    const SizedBox(height: 18),
                    _PeriodSwitch(
                      period: state.period,
                      onSelect: (period) =>
                          context.read<DashboardCubit>().select(period),
                    ),
                    const SizedBox(height: 18),
                    ..._content(state),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Isi dashboard untuk [state].
  List<Widget> _content(DashboardState state) {
    final stats = state.stats;

    if (stats == null) {
      if (state is DashboardFailure) {
        return [
          _FailureView(
            message: state.message,
            onRetry: () => context.read<DashboardCubit>().refresh(),
          ),
        ];
      }
      return const [DashboardSkeleton()];
    }

    return [
      if (state is DashboardFailure)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ErrorBanner(
            message: state.message,
            onRetry: () => context.read<DashboardCubit>().refresh(),
          ),
        ),
      _VisitorsCard(value: stats.totalVisitors),
      const SizedBox(height: 14),
      _MetricCard(
        label: context.trSafe('dashboard.valid', 'Valid'),
        value: stats.validTickets,
        icon: AppIcons.check,
        accent: context.colors.valid,
      ),
      // Pending offline queue section — tampil hanya bila ada item dan ScannerCubit tersedia.
      const _PendingQueueWrapper(),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.initials,
    required this.online,
    this.isChecking = false,
    this.onRefresh,
    required this.onProfileTap,
  });

  final String initials;
  final bool online;
  final bool isChecking;
  final VoidCallback? onRefresh;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: onProfileTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.surfaceAlt,
                    border: Border.all(color: context.colors.outline),
                  ),
                  child: ClipOval(
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.colors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ConnectionPill(
          online: online,
          isChecking: isChecking,
          onRefresh: onRefresh,
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.gate});

  final String name;
  final String gate;

  String _greetingKey() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'dashboard.goodMorning';
    if (hour < 15) return 'dashboard.goodAfternoon';
    if (hour < 19) return 'dashboard.goodEvening';
    return 'dashboard.goodNight';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.trSafe(_greetingKey(), 'Good afternoon'),
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13,
            color: context.colors.inkMuted,
          ),
        ),
        if (name.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            name,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: context.colors.ink,
              letterSpacing: -0.3,
            ),
          ),
        ],
        const SizedBox(height: 3),
        Text(
          gate,
          style: TextStyle(
            fontSize: 12.5,
            color: context.colors.inkMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PeriodSwitch extends StatelessWidget {
  const _PeriodSwitch({required this.period, required this.onSelect});

  final StatsPeriod period;
  final ValueChanged<StatsPeriod> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        children: [
          for (final option in StatsPeriod.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: period == option
                        ? context.colors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    option == StatsPeriod.today
                        ? context.trSafe('dashboard.today', option.shortLabel)
                        : context.trSafe(
                            'dashboard.thisMonth',
                            option.shortLabel,
                          ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: period == option
                          ? context.colors.onPrimary
                          : context.colors.inkMuted,
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

class _VisitorsCard extends StatelessWidget {
  const _VisitorsCard({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSheet),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(AppIcons.group, color: context.colors.ink, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: context.colors.ink,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            context.trSafe('dashboard.visitors', 'Visitors'),
            style: TextStyle(
              fontSize: 12.5,
              color: context.colors.inkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: context.colors.ink,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.colors.inkMuted,
              fontWeight: FontWeight.w500,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        children: [
          Icon(AppIcons.error, size: 18, color: context.colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12.5,
                color: context.colors.ink,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: context.colors.primary,
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

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSheet),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        children: [
          Icon(AppIcons.wifiOff, size: 40, color: context.colors.inkMuted),
          const SizedBox(height: 12),
          Text(
            context.trSafe('dashboard.loadFailed', 'Metrik tidak dapat dimuat'),
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.colors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13,
              color: context.colors.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size(0, 48),
            ),
            child: Text(context.trSafe('common.retry', 'Coba lagi')),
          ),
        ],
      ),
    );
  }
}

/// Pembungkus antrean pending yang aman: tidak crash jika ScannerCubit tidak ada di tree (mis. unit test terisolasi).
class _PendingQueueWrapper extends StatelessWidget {
  const _PendingQueueWrapper();

  @override
  Widget build(BuildContext context) {
    ScannerCubit? cubit;
    try {
      cubit = BlocProvider.of<ScannerCubit>(context, listen: false);
    } catch (_) {
      cubit = null;
    }

    if (cubit == null) return const SizedBox.shrink();

    return BlocBuilder<ScannerCubit, ScannerState>(
      bloc: cubit,
      buildWhen: (prev, curr) => prev.pendingSync != curr.pendingSync,
      builder: (wrapperContext, scannerState) {
        if (!scannerState.hasPendingSync) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 18),
          child: _PendingQueueSection(
            scannerCubit: cubit,
            onSyncDone: () {
              wrapperContext.read<DashboardCubit>().refresh();
            },
            onMessage: (message, isError) {
              if (wrapperContext.mounted) {
                if (isError) {
                  AppSnackbar.danger(wrapperContext, message);
                } else {
                  AppSnackbar.info(wrapperContext, message);
                }
              }
            },
          ),
        );
      },
    );
  }
}

/// List tiket offline yang menunggu dikirim ke server.
///
/// Ditampilkan di bawah card Pengunjung/Valid/Ditolak saat ada item di antrean
/// offline. Setiap item menampilkan kode tiket, mode, jumlah pengunjung riil,
/// dan waktu scan. Tombol "Kirim ke Server" memicu sync manual.
class _PendingQueueSection extends StatefulWidget {
  const _PendingQueueSection({
    this.scannerCubit,
    this.onSyncDone,
    this.onMessage,
  });

  final ScannerCubit? scannerCubit;
  final VoidCallback? onSyncDone;
  final void Function(String message, bool isError)? onMessage;

  @override
  State<_PendingQueueSection> createState() => _PendingQueueSectionState();
}

class _PendingQueueSectionState extends State<_PendingQueueSection> {
  bool _syncingAll = false;
  String? _syncingItemId;

  Future<void> _syncSingle(QueuedScan item) async {
    if (_syncingAll || _syncingItemId != null) return;

    final connectivity = context.read<DemoConnectivity>();
    if (!connectivity.online) {
      AppSnackbar.warning(
        context,
        context.trSafe(
          'dashboard.syncNoConnection',
          'Tidak ada koneksi internet. Coba lagi saat sudah online.',
        ),
      );
      return;
    }

    setState(() => _syncingItemId = item.id);
    try {
      final cubit = widget.scannerCubit ?? context.read<ScannerCubit>();
      final successMsg = context.trSafe(
        'dashboard.syncSingleSuccess',
        'Tiket {code} berhasil dikonfirmasi dan dikirim',
        namedArgs: {'code': item.ticketCode},
      );
      await cubit.syncSingleQueueItem(item);

      if (widget.onMessage != null) {
        widget.onMessage!(successMsg, false);
      } else if (mounted) {
        AppSnackbar.success(context, successMsg);
      }
      widget.onSyncDone?.call();
      if (mounted) setState(() {});
    } catch (e) {
      if (widget.onMessage != null) {
        widget.onMessage!('Gagal mengirim tiket ${item.ticketCode}: $e', true);
      } else if (mounted) {
        AppSnackbar.danger(
          context,
          'Gagal mengirim tiket ${item.ticketCode}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncingItemId = null);
      }
    }
  }

  Future<void> _cancelItem(QueuedScan item) async {
    if (_syncingAll || _syncingItemId != null) return;

    final cubit = widget.scannerCubit ?? context.read<ScannerCubit>();
    final successMessage = context.trSafe(
      'dashboard.cancelQueueSuccess',
      'Antrean tiket {code} berhasil dibatalkan',
      namedArgs: {'code': item.ticketCode},
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          context.trSafe(
            'dashboard.cancelQueueTitle',
            'Batalkan Antrean Tiket?',
          ),
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.colors.ink,
          ),
        ),
        content: Text(
          context.trSafe(
            'dashboard.cancelQueueMessage',
            'Tiket {code} akan dihapus dari antrean offline dan tidak akan dikirim ke server.',
            namedArgs: {'code': item.ticketCode},
          ),
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13.5,
            color: context.colors.inkMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              context.trSafe('dashboard.cancelQueueBack', 'Kembali'),
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                color: context.colors.inkMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              context.trSafe('dashboard.cancelQueueConfirm', 'Ya, Batalkan'),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await cubit.cancelQueueItem(item.id);

      if (widget.onMessage != null) {
        widget.onMessage!(successMessage, false);
      } else if (mounted) {
        AppSnackbar.info(context, successMessage);
      }
      widget.onSyncDone?.call();
      if (mounted) setState(() {});
    } catch (e) {
      if (widget.onMessage != null) {
        widget.onMessage!('Gagal membatalkan antrean: $e', true);
      } else if (mounted) {
        AppSnackbar.danger(context, 'Gagal membatalkan antrean: $e');
      }
    }
  }

  Future<void> _syncQueue() async {
    if (_syncingAll || _syncingItemId != null) return;

    final connectivity = context.read<DemoConnectivity>();
    if (!connectivity.online) {
      AppSnackbar.warning(
        context,
        context.trSafe(
          'dashboard.syncNoConnection',
          'Tidak ada koneksi internet. Coba lagi saat sudah online.',
        ),
      );
      return;
    }

    setState(() => _syncingAll = true);
    try {
      final cubit = widget.scannerCubit ?? context.read<ScannerCubit>();
      final synced = await cubit.processOfflineQueue();
      if (!mounted) return;

      if (synced > 0) {
        AppSnackbar.success(
          context,
          context.trSafe(
            'dashboard.syncSuccess',
            '{count} tiket berhasil dikirim ke server',
            namedArgs: {'count': '$synced'},
          ),
        );
        widget.onSyncDone?.call();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.danger(context, 'Gagal mengirim antrean: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _syncingAll = false);
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m WITA';
  }

  Widget _buildTicketCard(QueuedScan item, AppColors c) {
    final isCheckIn = item.mode == 'checkIn' || item.mode == 'check_in';
    final timeStr = _formatTime(item.queuedAt);
    final visitors = item.actualVisitorCount;
    final isThisItemSyncing = _syncingItemId == item.id;
    final isBusy = _syncingAll || _syncingItemId != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.outline.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCheckIn
                      ? c.valid.withValues(alpha: 0.12)
                      : c.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCheckIn ? AppIcons.checkCircle : AppIcons.qrScanner,
                  size: 18,
                  color: isCheckIn ? c.valid : c.inkMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.ticketCode,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          isCheckIn ? 'Check-In' : 'Periksa',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isCheckIn ? c.valid : c.inkMuted,
                          ),
                        ),
                        if (visitors != null && visitors > 0) ...[
                          Text(
                            ' · ',
                            style: TextStyle(fontSize: 12, color: c.inkMuted),
                          ),
                          Text(
                            context.trSafe(
                              'dashboard.pendingItemVisitors',
                              '{count} orang hadir',
                              namedArgs: {'count': '$visitors'},
                            ),
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.primary,
                            ),
                          ),
                        ],
                        Text(
                          ' · $timeStr',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            color: c.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: c.outline.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              // Tombol Batal Per-Tiket
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : () => _cancelItem(item),
                  icon: Icon(Icons.close_rounded, size: 15, color: c.inkMuted),
                  label: Text(
                    context.trSafe('dashboard.cancelTicket', 'Batal'),
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: c.inkMuted,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.outline),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 38),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol Konfirmasi Per-Tiket
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : () => _syncSingle(item),
                  icon: isThisItemSyncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined, size: 16),
                  label: Text(
                    isThisItemSyncing
                        ? context.trSafe(
                            'dashboard.sendingToServer',
                            'Mengirim...',
                          )
                        : context.trSafe(
                            'dashboard.confirmTicket',
                            'Konfirmasi',
                          ),
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: c.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 38),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = OfflineQueueDAO().getAll();
    final totalCount = items.length;

    if (totalCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Judul & Badge jumlah
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppIcons.history,
                      size: 16,
                      color: c.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.trSafe(
                      'dashboard.pendingQueue',
                      'Menunggu Dikirim',
                    ),
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: c.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  context.trSafe(
                    'dashboard.pendingQueueCount',
                    '{count} tiket menunggu',
                    namedArgs: {'count': '$totalCount'},
                  ),
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // List item pending dengan tombol aksi terpisah per-tiket
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildTicketCard(items[i], c),
          ],

          if (totalCount > 1) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: (_syncingAll || _syncingItemId != null)
                    ? null
                    : _syncQueue,
                icon: _syncingAll
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(c.primary),
                        ),
                      )
                    : Icon(
                        Icons.cloud_upload_outlined,
                        size: 18,
                        color: c.primary,
                      ),
                label: Text(
                  _syncingAll
                      ? context.trSafe(
                          'dashboard.sendingToServer',
                          'Mengirim...',
                        )
                      : context.trSafe(
                          'dashboard.confirmAll',
                          'Konfirmasi Semua ({count})',
                          namedArgs: {'count': '$totalCount'},
                        ),
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.primary.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

