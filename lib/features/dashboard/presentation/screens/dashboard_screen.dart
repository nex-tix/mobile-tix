import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/demo_connectivity.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/i18n_helper.dart';
import '../../../auth/logic/session_state.dart';
import '../../../../core/ui/widgets/app_snackbar.dart';
import '../../../../shared/widgets/inline_status.dart';
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
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
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
      Row(
        children: [
          Expanded(
            child: _MetricCard(
              label: context.trSafe('dashboard.valid', 'Valid'),
              value: stats.validTickets,
              icon: AppIcons.check,
              accent: context.colors.valid,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              label: context.trSafe('dashboard.rejected', 'Rejected'),
              value: stats.rejectedTickets,
              icon: AppIcons.close,
              accent: context.colors.primary,
            ),
          ),
        ],
      ),
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
