import 'package:flutter/material.dart';
import '../models/transaction.dart';

class QuickAdd extends StatefulWidget {
  const QuickAdd({super.key});

  @override
  State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  final _amountController = TextEditingController();
  String _selectedCategory = '식비';
  bool _isExpense = true;

  List<String> get _categories =>
      _isExpense ? expenseCategories : incomeCategories;

  @override
  Widget build(BuildContext context) {
    // 카테고리가 현재 선택한 타입에 없으면 첫 번째로 변경
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = _categories.first;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '빠른 입력',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                SegmentedButton<bool>(
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
                  selected: {_isExpense},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _isExpense = newSelection.first;
                      _selectedCategory = _categories.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '금액',
                      prefixText: '₩ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: '카테고리',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(
                              getCategoryIcon(category),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(category),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _amountController.text.isEmpty
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${_isExpense ? '지출' : '수입'} ₩${_amountController.text} 저장됨',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        _amountController.clear();
                      },
                icon: const Icon(Icons.add),
                label: const Text('추가'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
