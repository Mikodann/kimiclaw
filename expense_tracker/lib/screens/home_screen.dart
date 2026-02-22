import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../widgets/quick_add.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  void _loadDummyData() {
    setState(() {
      transactions = [
        Transaction(
          id: '1',
          title: '점심',
          amount: 12000,
          category: '식비',
          date: DateTime.now(),
          isExpense: true,
        ),
        Transaction(
          id: '2',
          title: '지하철',
          amount: 1400,
          category: '교통',
          date: DateTime.now().subtract(const Duration(hours: 3)),
          isExpense: true,
        ),
        Transaction(
          id: '3',
          title: '월급',
          amount: 3000000,
          category: '수입',
          date: DateTime.now().subtract(const Duration(days: 1)),
          isExpense: false,
        ),
      ];
    });
  }

  double get _totalExpense => transactions
      .where((t) => t.isExpense)
      .fold(0, (sum, t) => sum + t.amount);

  double get _totalIncome => transactions
      .where((t) => !t.isExpense)
      .fold(0, (sum, t) => sum + t.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('가계부'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 요약 카드
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    '이번달 수입',
                    _totalIncome,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    '이번달 지출',
                    _totalExpense,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // 빠른 입력
          const QuickAdd(),

          // 최근 내역
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '최근 내역',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final t = transactions[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: t.isExpense
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                            child: Icon(
                              t.isExpense
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: t.isExpense ? Colors.red : Colors.green,
                            ),
                          ),
                          title: Text(t.title),
                          subtitle: Text('${t.category} · ${_formatDate(t.date)}'),
                          trailing: Text(
                            '${t.isExpense ? '-' : '+'}${_formatAmount(t.amount)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: t.isExpense ? Colors.red : Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatAmount(amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    return '₩${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
