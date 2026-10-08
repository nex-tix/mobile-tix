import 'package:mobile_tix/core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/demo_connectivity.dart';
import '../../../auth/logic/session_state.dart';
import '../../../../shared/widgets/loading_state.dart';
import '../../bloc/dashboard_cubit.dart';
import '../../bloc/dashboard_state.dart';

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
      backgroundColor: const Color(0xFF2A363B),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    staffName: staff?.name ?? 'Raya',
                    initials: staff?.initials ?? 'R',
                    gate: checkpoint?.gate ?? 'Gate 1',
                    online: connectivity.online,
                    onProfileTap: () =>
                        Navigator.of(context).pushNamed('/profile'),
                  ),
                  const SizedBox(height: 20),
                  _Greeting(name: staff?.name ?? 'Raya'),
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
            );
          },
        ),
      ),
    );
  }

  /// Isi dashboard untuk [state].
  ///
  /// Tiga kemungkinan, dan tidak ada yang menampilkan angka palsu:
  /// - belum ada data sama sekali → skeleton (atau layar gagal bila permintaan
  ///   pertamanya yang gagal);
  /// - ada data → kartu metrik, ditambah banner kecil bila pemuatan ulang gagal
  ///   (angka lama tetap ditampilkan, karena itu masih data yang benar).
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
      return const [
        LoadingState(rows: 3, label: 'Memuat metrik…', rowHeight: 64),
      ];
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
              label: 'Valid',
              value: stats.validTickets,
              icon: AppIcons.check,
              accent: const Color(0xFF34D399),
              tint: const Color(0x2610B981),
              border: const Color(0x4D10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              label: 'Rejected',
              value: stats.rejectedTickets,
              icon: AppIcons.close,
              accent: const Color(0xFFCF4647),
              tint: const Color(0x26CF4647),
              border: const Color(0x4DCF4647),
            ),
          ),
        ],
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.staffName,
    required this.initials,
    required this.gate,
    required this.online,
    required this.onProfileTap,
  });

  final String staffName;
  final String initials;
  final String gate;
  final bool online;
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
                    color: const Color(0xFF1E272B),
                    border: Border.all(color: const Color(0xFF334147), width: 2),
                  ),
                  child: ClipOval(
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF5D061),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staffName,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF8F6F6),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      gate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA3B1B7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0x3310B981),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0x6610B981)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online
                      ? const Color(0xFF10B981)
                      : const Color(0xFFCF4647),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                online ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: online
                      ? const Color(0xFF34D399)
                      : const Color(0xFFCF4647),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Good afternoon',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13,
            color: Color(0xFFA3B1B7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF8F6F6),
            letterSpacing: -0.3,
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
        color: const Color(0xFF1E272B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334147)),
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
                        ? const Color(0xFFCF4647)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    option.shortLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: period == option
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

class _VisitorsCard extends StatelessWidget {
  const _VisitorsCard({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF212B2F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3E4E55)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF334147),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              AppIcons.group,
              color: Color(0xFFF8F6F6),
              size: 22,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$value',
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF8F6F6),
              letterSpacing: -0.5,
            ),
          ),
          const Text(
            'Visitors',
            style: TextStyle(
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.tint,
    required this.border,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color accent;
  final Color tint;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF212B2F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF3E4E55)),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint,
              border: Border.all(color: border),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            '$value',
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF8F6F6),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFA3B1B7),
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

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF212B2F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3E4E55)),
      ),
      child: Column(
        children: [
          const Icon(
            AppIcons.wifiOff,
            size: 40,
            color: Color(0xFF6B7E86),
          ),
          const SizedBox(height: 12),
          const Text(
            'Metrik tidak dapat dimuat',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF8F6F6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13,
              color: Color(0xFFA3B1B7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF4647),
              foregroundColor: const Color(0xFFF8F6F6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size(0, 48),
            ),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
