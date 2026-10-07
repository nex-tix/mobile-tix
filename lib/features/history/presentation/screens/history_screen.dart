import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/ticket_status.dart';
import '../../data/models/ledger_entry.dart';
import '../../logic/history_state.dart';
import '../widgets/history_row.dart';

/// Screen 13: History All matching `newDesign/13._history_all/code.html`.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum _HistoryFilterCategory { all, valid, rejected }

class _HistoryScreenState extends State<HistoryScreen> {
  _HistoryFilterCategory _selectedCategory = _HistoryFilterCategory.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HistoryState>().loadOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryState>();

    // Filter by category
    final List<LedgerEntry> displayedEntries = history.all.where((e) {
      return switch (_selectedCategory) {
        _HistoryFilterCategory.all => true,
        _HistoryFilterCategory.valid => e.status == TicketStatus.valid,
        _HistoryFilterCategory.rejected => e.status != TicketStatus.valid,
      };
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF2A363B),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar & Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(
                      fontFamily: 'Barlow',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF8F6F6),
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '${displayedEntries.length} scans',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFA3B1B7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Segmented Filter Tabs: All, Valid, Rejected
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E272B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334147)),
                ),
                child: Row(
                  children: [
                    _filterTab(
                      label: 'All',
                      category: _HistoryFilterCategory.all,
                    ),
                    _filterTab(
                      label: 'Valid',
                      category: _HistoryFilterCategory.valid,
                    ),
                    _filterTab(
                      label: 'Rejected',
                      category: _HistoryFilterCategory.rejected,
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Ticket List
            Expanded(
              child: RefreshIndicator(
                onRefresh: history.refresh,
                color: const Color(0xFFCF4647),
                backgroundColor: const Color(0xFF212B2F),
                child: history.loading && displayedEntries.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFFCF4647),
                        ),
                      )
                    : displayedEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.history_toggle_off_rounded,
                              size: 48,
                              color: Color(0xFF4B5E66),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Tidak ada data tiket',
                              style: TextStyle(
                                fontFamily: 'Barlow',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFA3B1B7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 110),
                        itemCount: displayedEntries.length,
                        itemBuilder: (context, index) {
                          return HistoryRow(entry: displayedEntries[index]);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterTab({
    required String label,
    required _HistoryFilterCategory category,
  }) {
    final isSelected = _selectedCategory == category;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedCategory = category);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFCF4647) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Barlow',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? const Color(0xFFF8F6F6) : const Color(0xFFA3B1B7),
            ),
          ),
        ),
      ),
    );
  }
}
