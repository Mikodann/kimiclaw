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
  bool _showExpense = true; // true: 지출, false: 수입

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
      Transaction(id: '7', title: '볼너스', amount: 500000, category: '볼너스', date: DateTime.now(), isExpense: false),
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
    final categoryData = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 지출/수입 토글
            Center(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('지출'),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('수입'),
                  ),
                ],
                selected: {_showExpense},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _showExpense = newSelection.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // 총액
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '이번달 총 ${_showExpense ? '지출' : '수입'}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatAmount(_totalAmount),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _showExpense ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 파이 차트
            if (categoryData.isNotEmpty)
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieSections(categoryData),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              )
            else
              const SizedBox(
                height: 250,
                child: Center(
                  child: Text('데이터가 없습니다'),
                ),
              ),
            const SizedBox(height: 24),

            // 카테고리별 목록
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      '카테고리별 ${_showExpense ? '지출' : '수입'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...categoryData.map((entry) {
                    final percentage = _totalAmount > 0
                        ? (entry.value / _totalAmount * 100).toStringAsFixed(1)
                        : '0.0';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: getCategoryColor(entry.key).withOpacity(0.2),
                        child: Icon(
                          getCategoryIcon(entry.key),
                          color: getCategoryColor(entry.key),
                        ),
                      ),
                      title: Text(entry.key),
                      subtitle: Text('$percentage%'),
                      trailing: Text(
                        _formatAmount(entry.value),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(List<MapEntry<String, double>> data) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final percentage = _totalAmount > 0 ? data.value / _totalAmount : 0;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: data.value,
        title: '${(percentage * 100).toStringAsFixed(0)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  String _formatAmount(double amount) {
    return '₩${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }
}
