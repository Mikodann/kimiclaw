import 'package:flutter/material.dart';
import '../models/transaction.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({super.key});

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  List<Investment> investments = [];
  bool _showAddForm = false;

  final _titleController = TextEditingController();
  final _principalController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _memoController = TextEditingController();
  String _selectedType = '적금';

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  void _loadDummyData() {
    setState(() {
      investments = [
        Investment(
          id: '1',
          title: '주택청약종합저축',
          type: '적금',
          principal: 2400000,
          currentValue: 2450000,
          startDate: DateTime.now().subtract(const Duration(days: 365)),
          memo: '매월 20만원',
        ),
        Investment(
          id: '2',
          title: '삼성전자',
          type: '주식',
          principal: 5000000,
          currentValue: 6200000,
          startDate: DateTime.now().subtract(const Duration(days: 180)),
          memo: '장기 보유',
        ),
        Investment(
          id: '3',
          title: '비트코인',
          type: '코인',
          principal: 1000000,
          currentValue: 850000,
          startDate: DateTime.now().subtract(const Duration(days: 90)),
          memo: '손절 고민중',
        ),
      ];
    });
  }

  double get _totalPrincipal => investments.fold(0, (sum, i) => sum + i.principal);
  double get _totalCurrentValue => investments.fold(0, (sum, i) => sum + i.currentValue);
  double get _totalProfit => _totalCurrentValue - _totalPrincipal;
  double get _totalProfitRate => _totalPrincipal > 0 ? (_totalProfit / _totalPrincipal) * 100 : 0;

  Map<String, List<Investment>> get _investmentsByType {
    final Map<String, List<Investment>> map = {};
    for (final type in investmentTypes) {
      map[type] = [];
    }
    for (final inv in investments) {
      map[inv.type]?.add(inv);
    }
    return map;
  }

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
                        '재테크',
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
                          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withOpacity(0.4),
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

          // 총 자산 요약
          SliverToBoxAdapter(
            child: _buildSummaryCard(),
          ),

          // 추가 폼
          if (_showAddForm)
            SliverToBoxAdapter(
              child: _buildAddForm(),
            ),

          // 투자 유형별 요약
          SliverToBoxAdapter(
            child: _buildTypeSummary(),
          ),

          // 투자 목록 헤더
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                children: [
                  Text(
                    '투자 목록 ${investments.length}개',
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

          // 투자 목록
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final investment = investments[index];
                  return _buildInvestmentCard(investment);
                },
                childCount: investments.length,
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

  Widget _buildSummaryCard() {
    final isProfit = _totalProfit >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [const Color(0xFF22C55E).withOpacity(0.3), const Color(0xFF16A34A).withOpacity(0.3)]
              : [const Color(0xFFFF6B6B).withOpacity(0.3), const Color(0xFFFF8E53).withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isProfit ? const Color(0xFF22C55E) : const Color(0xFFFF6B6B))
              .withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? const Color(0xFF22C55E) : const Color(0xFFFF6B6B))
                .withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '총 투자금',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatAmount(_totalPrincipal),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '현재 가치',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatAmount(_totalCurrentValue),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isProfit ? const Color(0xFF22C55E) : const Color(0xFFFF6B6B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isProfit
                  ? const Color(0xFF22C55E).withOpacity(0.2)
                  : const Color(0xFFFF6B6B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isProfit
                    ? const Color(0xFF22C55E).withOpacity(0.3)
                    : const Color(0xFFFF6B6B).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  color: isProfit ? const Color(0xFF22C55E) : const Color(0xFFFF6B6B),
                ),
                const SizedBox(width: 8),
                Text(
                  '${isProfit ? '+' : ''}${_formatAmount(_totalProfit)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isProfit ? const Color(0xFF22C55E) : const Color(0xFFFF6B6B),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_totalProfitRate.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 14,
                    color: isProfit ? const Color(0xFF22C55E) : const Color(0xFFFF6B6B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              '투자 유형별',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: investmentTypes.map((type) {
              final typeInvestments = _investmentsByType[type] ?? [];
              final typePrincipal = typeInvestments.fold(0.0, (sum, i) => sum + i.principal);
              final typeCurrent = typeInvestments.fold(0.0, (sum, i) => sum + i.currentValue);
              final typeProfit = typeCurrent - typePrincipal;
              final isProfit = typeProfit >= 0;

              if (typeInvestments.isEmpty) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isProfit
                        ? const Color(0xFF22C55E).withOpacity(0.3)
                        : const Color(0xFFFF6B6B).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatAmount(typeCurrent),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${isProfit ? '+' : ''}${(typeProfit / typePrincipal * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: isProfit ? const Color(0xFF22C55E) : const Color(0xFFFF6B6B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
          color: const Color(0xFF22C55E).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '새 투자 추가',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildInputField('항목명', _titleController, Icons.label),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: '투자 유형',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              dropdownColor: const Color(0xFF2A2A3E),
              style: const TextStyle(color: Colors.white),
              items: investmentTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  '원금',
                  _principalController,
                  Icons.account_balance_wallet,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  '현재 가치',
                  _currentValueController,
                  Icons.show_chart,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInputField('메모 (선택)', _memoController, Icons.note),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _addInvestment,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
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
          prefixIcon: Icon(icon, color: const Color(0xFF22C55E), size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  void _addInvestment() {
    final principal = double.tryParse(_principalController.text) ?? 0;
    final currentValue = double.tryParse(_currentValueController.text) ?? 0;

    if (_titleController.text.isEmpty || principal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('항목명과 원금을 입력해주세요')),
      );
      return;
    }

    setState(() {
      investments.add(Investment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        type: _selectedType,
        principal: principal,
        currentValue: currentValue,
        startDate: DateTime.now(),
        memo: _memoController.text.isEmpty ? null : _memoController.text,
      ));

      _titleController.clear();
      _principalController.clear();
      _currentValueController.clear();
      _memoController.clear();
      _showAddForm = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('투자가 추가되었습니다')),
    );
  }

  Widget _buildInvestmentCard(Investment investment) {
    final isProfit = investment.isProfit;
    final days = DateTime.now().difference(investment.startDate).inDays;

    return Dismissible(
      key: Key(investment.id),
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
          investments.removeWhere((i) => i.id == investment.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('투자가 삭제되었습니다')),
        );
      },
      child: GestureDetector(
        onTap: () => _showEditDialog(investment),
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
              color: isProfit
                  ? const Color(0xFF22C55E).withOpacity(0.3)
                  : const Color(0xFFFF6B6B).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isProfit
                          ? const Color(0xFF22C55E).withOpacity(0.2)
                          : const Color(0xFFFF6B6B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      investment.type,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isProfit ? const Color(0xFF22C55E) : const Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$days일째',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                investment.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (investment.memo != null) ...[
                const SizedBox(height: 4),
                Text(
                  investment.memo!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '원금',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        _formatAmount(investment.principal),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '현재 가치',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        _formatAmount(investment.currentValue),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isProfit ? const Color(0xFF22C55E) : const Color(0xFFFF6B6B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isProfit
                      ? const Color(0xFF22C55E).withOpacity(0.1)
                      : const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isProfit ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: isProfit ? const Color(0xFF22C55E) : const Color(0xFFFF6B6B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isProfit ? '+' : ''}${_formatAmount(investment.profit)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isProfit ? const Color(0xFF22C55E) : const Color(0xFFFF6B6B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${investment.profitRate.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isProfit ? const Color(0xFF22C55E) : const Color(0xFFFF6B6B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(Investment investment) {
    final titleController = TextEditingController(text: investment.title);
    final principalController = TextEditingController(text: investment.principal.toStringAsFixed(0));
    final currentController = TextEditingController(text: investment.currentValue.toStringAsFixed(0));
    final memoController = TextEditingController(text: investment.memo ?? '');
    String selectedType = investment.type;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('투자 수정', style: TextStyle(color: Colors.white)),
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
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: const Color(0xFF2A2A3E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '투자 유형',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
                items: investmentTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedType = value!;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: principalController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '원금',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: currentController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '현재 가치',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: memoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '메모',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
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
                investment.title = titleController.text;
                investment.type = selectedType;
                investment.principal = double.tryParse(principalController.text) ?? investment.principal;
                investment.currentValue = double.tryParse(currentController.text) ?? investment.currentValue;
                investment.memo = memoController.text.isEmpty ? null : memoController.text;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('투자가 수정되었습니다')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
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
    _principalController.dispose();
    _currentValueController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}
