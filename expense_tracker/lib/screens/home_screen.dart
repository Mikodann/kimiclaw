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
  BudgetSettings settings = BudgetSettings();
  bool _showSettings = false;

  final _startingController = TextEditingController();
  final _goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDummyData();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final loaded = await SettingsStorage.loadSettings();
    setState(() {
      settings = loaded;
      _startingController.text = settings.startingAmount.toStringAsFixed(0);
      _goalController.text = settings.monthlyGoal.toStringAsFixed(0);
    });
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
          category: '월급',
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

  double get _currentBalance => settings.startingAmount + _totalIncome - _totalExpense;

  double get _remainingToGoal => settings.monthlyGoal - (_totalIncome - _totalExpense);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // 헤더
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '안녕하세요, 동현님',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '이번달 현황',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 설정 버튼
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSettings = !_showSettings;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _showSettings ? Icons.close : Icons.settings,
                        color: const Color(0xFF00D4AA),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 설정 패널
          if (_showSettings)
            SliverToBoxAdapter(
              child: _buildSettingsPanel(),
            ),

          // 예상 잔액 카드
          SliverToBoxAdapter(
            child: _buildBalanceCard(),
          ),

          // 요약 카드 - 세로로 쌓기
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildGlassCard(
                    '수입',
                    _totalIncome,
                    const Color(0xFF00D4AA),
                    Icons.arrow_downward,
                  ),
                  const SizedBox(height: 12),
                  _buildGlassCard(
                    '지출',
                    _totalExpense,
                    const Color(0xFFFF6B6B),
                    Icons.arrow_upward,
                  ),
                ],
              ),
            ),
          ),

          // 빠른 입력
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: QuickAdd(),
            ),
          ),

          // 최근 내역 헤더
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text(
                    '최근 내역',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      '전체 보기',
                      style: TextStyle(
                        color: Color(0xFF00D4AA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 최근 내역 리스트
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final t = transactions[index];
                  return _buildTransactionItem(t);
                },
                childCount: transactions.length,
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

  Widget _buildSettingsPanel() {
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
            '예산 설정',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // 세로로 쌓기
          Column(
            children: [
              _buildSettingInput(
                '시작 금액',
                _startingController,
                Icons.account_balance_wallet,
              ),
              const SizedBox(height: 12),
              _buildSettingInput(
                '이번달 목표',
                _goalController,
                Icons.flag,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                setState(() {
                  settings.startingAmount =
                      double.tryParse(_startingController.text) ?? 0;
                  settings.monthlyGoal =
                      double.tryParse(_goalController.text) ?? 0;
                  _showSettings = false;
                });
                // 로컬에 저장
                await SettingsStorage.saveSettings(settings);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingInput(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A3E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF00D4AA), size: 20),
              prefixText: '₩ ',
              prefixStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    final isGoalMet = _remainingToGoal <= 0;
    final progress = settings.monthlyGoal > 0
        ? ((_totalIncome - _totalExpense) / settings.monthlyGoal).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGoalMet
              ? [const Color(0xFF00D4AA).withOpacity(0.3), const Color(0xFF00B4D8).withOpacity(0.3)]
              : [const Color(0xFFFF6B6B).withOpacity(0.3), const Color(0xFFFF8E53).withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isGoalMet ? const Color(0xFF00D4AA) : const Color(0xFFFF6B6B))
              .withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isGoalMet ? const Color(0xFF00D4AA) : const Color(0xFFFF6B6B))
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
                    '예상 잔액',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatAmount(_currentBalance),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isGoalMet
                      ? const Color(0xFF00D4AA).withOpacity(0.2)
                      : const Color(0xFFFF6B6B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isGoalMet
                        ? const Color(0xFF00D4AA).withOpacity(0.3)
                        : const Color(0xFFFF6B6B).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isGoalMet ? '목표 달성!' : '남은 목표',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isGoalMet
                          ? '+${_formatAmount(_remainingToGoal.abs())}'
                          : _formatAmount(_remainingToGoal),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isGoalMet ? const Color(0xFF00D4AA) : const Color(0xFFFF6B6B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (settings.monthlyGoal > 0) ...[
            const SizedBox(height: 24),
            // 애니메이션 진행률
            LayoutBuilder(
              builder: (context, constraints) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 2000),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedProgress, child) {
                    final displayProgress = progress >= 1.0 ? 1.0 : animatedProgress;
                    
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 배경 바
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 32,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        // 진행 바
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 32,
                            width: constraints.maxWidth * displayProgress,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isGoalMet
                                    ? [const Color(0xFF00D4AA), const Color(0xFF00B4D8)]
                                    : [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isGoalMet
                                          ? const Color(0xFF00D4AA)
                                          : const Color(0xFFFF6B6B))
                                      .withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 달려가는 캐릭터 (100% 미만일 때만)
                        if (progress < 1.0)
                          Positioned(
                            left: (constraints.maxWidth * displayProgress) - 28,
                            top: -4,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              builder: (context, wiggle, child) {
                                return Transform.translate(
                                  offset: Offset(wiggle * 3, 0),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.grey.shade200,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isGoalMet
                                                  ? const Color(0xFF00D4AA)
                                                  : const Color(0xFFFF6B6B))
                                              .withOpacity(0.6),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '🏃‍♂️',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        // 100% 달성 표시
                        if (progress >= 1.0)
                          Positioned(
                            right: 8,
                            top: 4,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF00D4AA),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  '🎉',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        // 퍼센트 텍스트 (중앙)
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              '${(displayProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '목표: ${_formatAmount(settings.monthlyGoal)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                Row(
                  children: [
                    if (progress >= 1.0) ...[
                      const Text(
                        '🎉 목표 달성!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00D4AA),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        '🏃 열심히 달리는 중... ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B6B),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGlassCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.8),
            const Color(0xFF2A2A3E).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatAmount(amount),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.6),
            const Color(0xFF2A2A3E).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: t.isExpense
                    ? [const Color(0xFFFF6B6B).withOpacity(0.3), const Color(0xFFFF8E53).withOpacity(0.3)]
                    : [const Color(0xFF00D4AA).withOpacity(0.3), const Color(0xFF00B4D8).withOpacity(0.3)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              getCategoryIcon(t.category),
              color: t.isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00D4AA),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${t.category} · ${_formatDate(t.date)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${t.isExpense ? '-' : '+'}${_formatAmount(t.amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: t.isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF00D4AA),
            ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '오늘';
    }
    return '${date.month}월 ${date.day}일';
  }

  @override
  void dispose() {
    _startingController.dispose();
    _goalController.dispose();
    super.dispose();
  }
}
