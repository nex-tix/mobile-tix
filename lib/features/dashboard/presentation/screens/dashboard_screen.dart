import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/connectivity/demo_connectivity.dart';
import '../../../auth/logic/session_state.dart';
import '../../../auth/presentation/widgets/profile_bottom_sheet.dart';
import '../../data/models/gate_stats.dart';
import '../../logic/dashboard_state.dart';

/// Screen 3: Dashboard (Today) matching `newDesign/3._dashboard_today/code.html`.
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
      if (mounted) context.read<DashboardState>().select(StatsPeriod.today);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    final dashboard = context.watch<DashboardState>();
    final connectivity = context.watch<DemoConnectivity>();
    final staff = session.staff;
    final checkpoint = session.checkpoint;
    final gate = checkpoint?.gate ?? 'Gate 1';
    final stats = dashboard.statsFor(gate);

    return Scaffold(
      backgroundColor: const Color(0xFF2A363B),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Status Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tappable Profile / Gate Info
                  InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: () => ProfileBottomSheet.show(context),
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
                              border: Border.all(
                                color: const Color(0xFF334147),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Center(
                                child: Text(
                                  staff?.initials ?? 'R',
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
                                staff?.name ?? 'Raya',
                                style: const TextStyle(
                                  fontFamily: 'Barlow',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF8F6F6),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                checkpoint?.gate ?? 'Gate 1',
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

                  // Online Badge
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
                            color: connectivity.online
                                ? const Color(0xFF10B981)
                                : const Color(0xFFCF4647),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          connectivity.online ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: connectivity.online
                                ? const Color(0xFF34D399)
                                : const Color(0xFFCF4647),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Greeting Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good afternoon',
                    style: TextStyle(
                      fontFamily: 'Barlow',
                      fontSize: 13,
                      color: Color(0xFFA3B1B7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    staff?.name ?? 'Raya',
                    style: const TextStyle(
                      fontFamily: 'Barlow',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF8F6F6),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Period Switch Control (Today vs This Month)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E272B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334147)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => dashboard.select(StatsPeriod.today),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: dashboard.period == StatsPeriod.today
                                ? const Color(0xFFCF4647)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Today',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Barlow',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: dashboard.period == StatsPeriod.today
                                  ? const Color(0xFFF8F6F6)
                                  : const Color(0xFFA3B1B7),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => dashboard.select(StatsPeriod.month),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: dashboard.period == StatsPeriod.month
                                ? const Color(0xFFCF4647)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'This Month',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Barlow',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: dashboard.period == StatsPeriod.month
                                  ? const Color(0xFFF8F6F6)
                                  : const Color(0xFFA3B1B7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Primary Stat Card: Visitors
              Container(
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
                        Icons.group_outlined,
                        color: Color(0xFFF8F6F6),
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${stats.entered}',
                      style: const TextStyle(
                        fontFamily: 'BarlowCondensed',
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
              ),
              const SizedBox(height: 14),

              // Secondary Stat Cards: Valid & Rejected (Grid 2-column)
              Row(
                children: [
                  // Valid Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF212B2F),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF3E4E55)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0x2610B981),
                              border: Border.all(color: const Color(0x4D10B981)),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Color(0xFF34D399),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${stats.valid}',
                            style: const TextStyle(
                              fontFamily: 'BarlowCondensed',
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF8F6F6),
                            ),
                          ),
                          const Text(
                            'Valid',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFA3B1B7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Rejected Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF212B2F),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF3E4E55)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0x26CF4647),
                              border: Border.all(color: const Color(0x4DCF4647)),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Color(0xFFCF4647),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${stats.refused}',
                            style: const TextStyle(
                              fontFamily: 'BarlowCondensed',
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF8F6F6),
                            ),
                          ),
                          const Text(
                            'Rejected',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFA3B1B7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
