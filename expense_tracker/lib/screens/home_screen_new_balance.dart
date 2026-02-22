  Widget _buildBalanceCard() {
    final isGoalMet = _remainingToGoal <= 0;
    final progress = settings.monthlyGoal > 0
        ? ((_totalIncome - _totalExpense) / settings.monthlyGoal).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.all(24),
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
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                              builder: (context, bounce, child) {
                                return Transform.translate(
                                  offset: Offset(0, bounce * -4),
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
                                        '🏃',
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