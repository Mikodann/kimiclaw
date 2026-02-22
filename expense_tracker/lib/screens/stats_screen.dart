import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Transaction> transactions = [];
  bool _showExpense = true;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  void _loadDummyData() {
    transactions = [
      Transaction(id: '1', title: '점심', amount: 12000, category: '식비', date: DateTime.now(), isExpense: true),
      Transaction(id: '2', title: '저녁', amount: 15000, category: '식비', date: DateTime.now(), isExpense: true),
      Transaction(id: '3', title: '지하철', amount: 1400, category: '교통', date: DateTime.now(), isExpense: true),
      Transaction(id: '4', title: '택시', amount: 8500, category: '교통', date: DateTime.now(), isExpense: true),
      Transaction(id: '5', title: '옷', amount: 45000, category: '쇼핑', date: DateTime.now(), isExpense: true),
      Transaction(id: '6', title: '월급', amount: 3000000, category: '월급', date: DateTime.now(), isExpense: false),
      Transaction(id: '7', title: '상여금', amount: 500000, category: '상여금', date: DateTime.now(), isExpense: false),
    ];
  }

  Map<String, double> get _categoryTotals {
    final Map<String, double> totals = {};
    for (final t in transactions.where((t) => t.isExpense == _showExpense)) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    return totals;
  }

  double get _totalAmount => transactions
      .where((t) => t.isExpense == _showExpense)
      .fold(0, (sum, t) => sum + t.amount);

  @override
  Widget build(BuildContext context) {
    // 비율 높은 순으로 정렬
    final categoryData = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0F),
              Color(0xFF1A1A2E),
              Color(0xFF0A0A0F),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 헤더
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Text(
                    '통계',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                // 지출/수입 토글
                _buildTypeToggle(),
                const SizedBox(height: 32),

                // 총액 카드
                _buildTotalCard(),
                const SizedBox(height: 32),

                // 파이 차트
                if (categoryData.isNotEmpty)
                  _buildPieChart(categoryData)
                else
                  const SizedBox(
                    height: 280,
                    child: Center(
                      child: Text(
                        '데이터가 없습니다',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),

                // 카테고리별 목록
                _buildCategoryList(categoryData),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('지출', true, const Color(0xFFFF6B6B)),
          _buildToggleButton('수입', false, const Color(0xFF00D4AA)),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isExpense, Color activeColor) {
    final isSelected = _showExpense == isExpense;
    return GestureDetector(
      onTap: () {
        setState(() {
          _showExpense = isExpense;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [activeColor, activeColor.withOpacity(0.8)],
                )
              : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade500,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _showExpense
              ? [const Color(0xFFFF6B6B).withOpacity(0.3), const Color(0xFFFF8E53).withOpacity(0.3)]
              : [const Color(0xFF00D4AA).withOpacity(0.3), const Color(0xFF00B4D8).withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (_showExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00D4AA))
              .withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (_showExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00D4AA))
                .withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '이번달 총 ${_showExpense ? '지출' : '수입'}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatAmount(_totalAmount),
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: _showExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00D4AA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<MapEntry<String, double>> data) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.6),
            const Color(0xFF2A2A3E).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: PieChart(
        PieChartData(
          sections: _buildPieSections(data),
          sectionsSpace: 3,
          centerSpaceRadius: 50,
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(List<MapEntry<String, double>> data) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final categoryData = entry.value;
      final percentage = _totalAmount > 0 ? categoryData.value / _totalAmount : 0;
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 95.0 : 85.0;
      // 카테고리 색상 사용
      final color = getCategoryColor(categoryData.key);

      return PieChartSectionData(
        color: color,
        value: categoryData.value,
        title: '${categoryData.key}\n${(percentage * 100).toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.2,
        ),
        titlePositionPercentageOffset: 0.6,
        badgeWidget: index < 3
            ? Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.1,
      );
    }).toList();
  }

  Widget _buildCategoryList(List<MapEntry<String, double>> data) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.6),
            const Color(0xFF2A2A3E).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  '카테고리별 ${_showExpense ? '지출' : '수입'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '높은 순',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...data.asMap().entries.map((entry) {
            final index = entry.key;
            final categoryData = entry.value;
            final percentage = _totalAmount > 0
                ? (categoryData.value / _totalAmount * 100).toStringAsFixed(1)
                : '0.0';
            final isTop3 = index < 3;

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isTop3
                      ? [
                          _getRankColor(index).withOpacity(0.2),
                          _getRankColor(index).withOpacity(0.1),
                        ]
                      : [
                          const Color(0xFF2A2A3E).withOpacity(0.5),
                          const Color(0xFF2A2A3E).withOpacity(0.3),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isTop3
                      ? _getRankColor(index).withOpacity(0.3)
                      : Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // 순위 뱃지
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: isTop3
                          ? LinearGradient(
                              colors: [
                                _getRankColor(index),
                                _getRankColor(index).withOpacity(0.8),
                              ],
                            )
                          : null,
                      color: isTop3 ? null : const Color(0xFF3A3A4E),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isTop3
                          ? [
                              BoxShadow(
                                color: _getRankColor(index).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isTop3 ? Colors.white : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 아이콘
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          getCategoryColor(categoryData.key).withOpacity(0.3),
                          getCategoryColor(categoryData.key).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      getCategoryIcon(categoryData.key),
                      color: getCategoryColor(categoryData.key),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryData.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _totalAmount > 0
                                ? categoryData.value / _totalAmount
                                : 0,
                            backgroundColor: Colors.grey.shade800,
                            valueColor: AlwaysStoppedAnimation(
                              getCategoryColor(categoryData.key),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 금액과 비율
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatAmount(categoryData.value),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // 금
      case 1:
        return const Color(0xFFC0C0C0); // 은
      case 2:
        return const Color(0xFFCD7F32); // 동
      default:
        return Colors.grey;
    }
  }

  String _formatAmount(double amount) {
    return '₩${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }
}
