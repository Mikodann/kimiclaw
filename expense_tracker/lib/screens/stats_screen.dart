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
      Transaction(id: '6', title: '월급', amount: 3000000, category: '수입', date: DateTime.now(), isExpense: false),
    ];
  }

  Map<String, double> get _categoryTotals {
    final Map<String, double> totals = {};
    for (final t in transactions.where((t) => t.isExpense)) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    return totals;
  }

  double get _totalExpense => transactions
      .where((t) => t.isExpense)
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
            // 총 지출
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      '이번달 총 지출',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatAmount(_totalExpense),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
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
              ),
            const SizedBox(height: 24),

            // 카테고리별 목록
            Card(
              child: Column(
                children: [
                  const ListTile(
                    title: Text(
                      '카테고리별 지출',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...categoryData.map((entry) {
                    final percentage = (entry.value / _totalExpense * 100).toStringAsFixed(1);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getCategoryColor(entry.key).withOpacity(0.2),
                        child: Icon(
                          _getCategoryIcon(entry.key),
                          color: _getCategoryColor(entry.key),
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
    ];

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final percentage = data.value / _totalExpense;

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

  Color _getCategoryColor(String category) {
    switch (category) {
      case '식비':
        return Colors.red;
      case '교통':
        return Colors.blue;
      case '쇼핑':
        return Colors.green;
      case '엔터':
        return Colors.orange;
      case '주거':
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '식비':
        return Icons.restaurant;
      case '교통':
        return Icons.directions_bus;
      case '쇼핑':
        return Icons.shopping_bag;
      case '엔터':
        return Icons.movie;
      case '주거':
        return Icons.home;
      default:
        return Icons.category;
    }
  }
}
