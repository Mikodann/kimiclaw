import 'package:flutter/material.dart';
import '../models/transaction.dart';

class InstallmentScreen extends StatefulWidget {
  const InstallmentScreen({super.key});

  @override
  State<InstallmentScreen> createState() => _InstallmentScreenState();
}

class _InstallmentScreenState extends State<InstallmentScreen> {
  List<Installment> installments = [];
  bool _showAddForm = false;

  final _titleController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _monthlyAmountController = TextEditingController();
  final _totalMonthsController = TextEditingController();
  final _currentMonthController = TextEditingController(text: '1');
  String _selectedCategory = '쇼핑';

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  void _loadDummyData() {
    setState(() {
      installments = [
        Installment(
          id: '1',
          title: '맥북 프로',
          totalAmount: 3000000,
          monthlyAmount: 200000,
          totalMonths: 15,
          currentMonth: 6,
          category: '쇼핑',
          startDate: DateTime.now().subtract(const Duration(days: 150)),
        ),
        Installment(
          id: '2',
          title: '에어컨',
          totalAmount: 1200000,
          monthlyAmount: 100000,
          totalMonths: 12,
          currentMonth: 3,
          category: '주거',
          startDate: DateTime.now().subtract(const Duration(days: 90)),
        ),
      ];
    });
  }

  double get _totalMonthlyInstallment => installments.fold(0, (sum, i) => sum + i.monthlyAmount);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // 헤더
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '할부 관리',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAddForm = !_showAddForm;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF00B4D8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4AA).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _showAddForm ? Icons.close : Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 월 할부 총액
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7B61FF).withOpacity(0.3),
                    const Color(0xFF00D4AA).withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF7B61FF).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B61FF).withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '이번달 할부 총액',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatAmount(_totalMonthlyInstallment),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 추가 폼
          if (_showAddForm)
            SliverToBoxAdapter(
              child: _buildAddForm(),
            ),

          // 할부 목록 헤더
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                children: [
                  Text(
                    '진행 중인 할부 ${installments.where((i) => !i.isComplete).length}개',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 할부 목록
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final installment = installments[index];
                  return _buildInstallmentCard(installment);
                },
                childCount: installments.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildAddForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.9),
            const Color(0xFF2A2A3E).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '새 할부 추가',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildInputField('항목명', _titleController, Icons.shopping_bag),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  '총 금액',
                  _totalAmountController,
                  Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  '월 할부금',
                  _monthlyAmountController,
                  Icons.calendar_today,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  '총 개월',
                  _totalMonthsController,
                  Icons.timelapse,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  '현재 회차',
                  _currentMonthController,
                  Icons.flag,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              dropdownColor: const Color(0xFF2A2A3E),
              style: const TextStyle(color: Colors.white),
              items: expenseCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        getCategoryIcon(category),
                        size: 18,
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
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                _addInstallment();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('추가'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF00D4AA), size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  void _addInstallment() {
    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0;
    final monthlyAmount = double.tryParse(_monthlyAmountController.text) ?? 0;
    final totalMonths = int.tryParse(_totalMonthsController.text) ?? 1;
    final currentMonth = int.tryParse(_currentMonthController.text) ?? 1;

    if (_titleController.text.isEmpty || totalAmount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('항목명과 금액을 입력해주세요')),
      );
      return;
    }

    setState(() {
      installments.add(Installment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        totalAmount: totalAmount,
        monthlyAmount: monthlyAmount,
        totalMonths: totalMonths,
        currentMonth: currentMonth,
        category: _selectedCategory,
        startDate: DateTime.now(),
      ));

      _titleController.clear();
      _totalAmountController.clear();
      _monthlyAmountController.clear();
      _totalMonthsController.clear();
      _currentMonthController.text = '1';
      _showAddForm = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('할부가 추가되었습니다')),
    );
  }

  Widget _buildInstallmentCard(Installment installment) {
    final progress = installment.currentMonth / installment.totalMonths;
    final isComplete = installment.isComplete;

    return Dismissible(
      key: Key(installment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '삭제',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      onDismissed: (_) {
        setState(() {
          installments.removeWhere((i) => i.id == installment.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('할부가 삭제되었습니다')),
        );
      },
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text('삭제 확인', style: TextStyle(color: Colors.white)),
            content: const Text(
              '정말 삭제하시겠습니까?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _showEditDialog(installment),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isComplete
                  ? const Color(0xFF00D4AA).withOpacity(0.3)
                  : Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          getCategoryColor(installment.category).withOpacity(0.3),
                          getCategoryColor(installment.category).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      getCategoryIcon(installment.category),
                      color: getCategoryColor(installment.category),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          installment.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${installment.category} · 월 ${_formatAmount(installment.monthlyAmount)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isComplete)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00D4AA).withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        '완료',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00D4AA),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // 진행 상황
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '진행 상황',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    '${installment.currentMonth}/${installment.totalMonths}회차',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation(
                    isComplete ? const Color(0xFF00D4AA) : const Color(0xFF7B61FF),
                  ),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '총 ${_formatAmount(installment.totalAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    '남은 금액: ${_formatAmount(installment.remainingAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isComplete ? const Color(0xFF00D4AA) : const Color(0xFFFF6B6B),
                    ),
                  ),
                ],
              ),
              if (!isComplete) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            installment.nextMonth();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00D4AA),
                          side: const BorderSide(color: Color(0xFF00D4AA)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('다음 회차로'),
                      ),
                    ),
                  ],
                ),
              ],
              // 수정 힌트
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '탭하여 수정 · 오른쪽으로 밀어 삭제',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(Installment installment) {
    final titleController = TextEditingController(text: installment.title);
    final totalController = TextEditingController(text: installment.totalAmount.toStringAsFixed(0));
    final monthlyController = TextEditingController(text: installment.monthlyAmount.toStringAsFixed(0));
    final totalMonthsController = TextEditingController(text: installment.totalMonths.toString());
    final currentMonthController = TextEditingController(text: installment.currentMonth.toString());
    String selectedCategory = installment.category;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('할부 수정', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '항목명',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '총 금액',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: monthlyController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '월 납입금',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: totalMonthsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: '총 개월',
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: currentMonthController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: '현재 회차',
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: const Color(0xFF2A2A3E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '카테고리',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
                items: expenseCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                installment.title = titleController.text;
                installment.totalAmount = double.tryParse(totalController.text) ?? installment.totalAmount;
                installment.monthlyAmount = double.tryParse(monthlyController.text) ?? installment.monthlyAmount;
                installment.totalMonths = int.tryParse(totalMonthsController.text) ?? installment.totalMonths;
                installment.currentMonth = int.tryParse(currentMonthController.text) ?? installment.currentMonth;
                installment.category = selectedCategory;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('할부가 수정되었습니다')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
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
    _totalAmountController.dispose();
    _monthlyAmountController.dispose();
    _totalMonthsController.dispose();
    _currentMonthController.dispose();
    super.dispose();
  }
}
