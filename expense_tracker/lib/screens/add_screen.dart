import 'package:flutter/material.dart';
import '../models/transaction.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = '식비';
  bool _isExpense = true;
  bool _isInstallment = false; // 할부 여부
  DateTime _selectedDate = DateTime.now();

  // 할부 관련
  final _totalMonthsController = TextEditingController();
  final _currentMonthController = TextEditingController(text: '1');

  List<String> get _categories =>
      _isExpense ? expenseCategories : incomeCategories;

  @override
  Widget build(BuildContext context) {
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = _categories.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('내역 추가'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 지출/수입 선택
            Center(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('지출', style: TextStyle(fontSize: 16)),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('수입', style: TextStyle(fontSize: 16)),
                  ),
                ],
                selected: {_isExpense},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isExpense = newSelection.first;
                    _isInstallment = false; // 수입으로 바꾸면 할부 해제
                    _selectedCategory = _categories.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // 지출일 때만: 일반/할부 선택
            if (_isExpense) ...[
              Center(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('일반 지출'),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('할부'),
                    ),
                  ],
                  selected: {_isInstallment},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _isInstallment = newSelection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 금액
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: _isInstallment ? '총 금액' : '금액',
                prefixText: '₩ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 할부일 때: 월 납입금 표시
            if (_isInstallment) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF00D4AA),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '월 납입금: ${_calculateMonthlyAmount()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 총 개월 / 현재 회차 - 세로로 쌓기
              Column(
                children: [
                  TextField(
                    controller: _totalMonthsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '총 개월',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _currentMonthController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '현재 회차',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
                  Expanded(
                    child: TextField(
                      controller: _currentMonthController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '현재 회차',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // 내용
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '내용',
                hintText: _isExpense
                    ? (_isInstallment ? '예: 맥북, 에어컨' : '예: 점심, 택시')
                    : '예: 월급, 상여금',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 카테고리
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        getCategoryIcon(category),
                        color: getCategoryColor(category),
                      ),
                      const SizedBox(width: 8),
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
            const SizedBox(height: 16),

            // 날짜
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              leading: const Icon(Icons.calendar_today),
              title: const Text('날짜'),
              subtitle: Text(
                '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 32),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text(
                  '저장',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateMonthlyAmount() {
    final total = double.tryParse(_amountController.text) ?? 0;
    final months = int.tryParse(_totalMonthsController.text) ?? 1;
    if (total == 0 || months == 0) return '₩0';
    final monthly = total / months;
    return '₩${monthly.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  void _save() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('금액을 입력해주세요')),
      );
      return;
    }

    if (_isInstallment) {
      // 할부 저장
      final totalAmount = double.parse(_amountController.text);
      final totalMonths = int.tryParse(_totalMonthsController.text) ?? 1;
      final currentMonth = int.tryParse(_currentMonthController.text) ?? 1;
      final monthlyAmount = totalAmount / totalMonths;

      final installment = Installment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.isEmpty
            ? _selectedCategory
            : _titleController.text,
        totalAmount: totalAmount,
        monthlyAmount: monthlyAmount,
        totalMonths: totalMonths,
        currentMonth: currentMonth,
        category: _selectedCategory,
        startDate: _selectedDate,
      );

      // TODO: 할부 목록에 저장
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '할부 "${installment.title}" ${_formatAmount(monthlyAmount)}/월 × $totalMonths개월 저장됨',
          ),
        ),
      );
    } else {
      // 일반 거래 저장
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.isEmpty
            ? _selectedCategory
            : _titleController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        date: _selectedDate,
        isExpense: _isExpense,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_isExpense ? '지출' : '수입'} ${_formatAmount(transaction.amount)} 저장됨',
          ),
        ),
      );
    }

    _titleController.clear();
    _amountController.clear();
    _totalMonthsController.clear();
    _currentMonthController.text = '1';
    setState(() {
      _selectedDate = DateTime.now();
      _isInstallment = false;
    });
  }

  String _formatAmount(double amount) {
    return '₩${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _totalMonthsController.dispose();
    _currentMonthController.dispose();
    super.dispose();
  }
}
