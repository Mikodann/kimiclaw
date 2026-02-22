import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isExpense;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.isExpense,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'isExpense': isExpense,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      isExpense: json['isExpense'],
    );
  }
}

// 설정 클래스
class BudgetSettings {
  double startingAmount;
  double monthlyGoal;

  BudgetSettings({
    this.startingAmount = 0,
    this.monthlyGoal = 0,
  });

  Map<String, dynamic> toJson() => {
    'startingAmount': startingAmount,
    'monthlyGoal': monthlyGoal,
  };

  factory BudgetSettings.fromJson(Map<String, dynamic> json) {
    return BudgetSettings(
      startingAmount: (json['startingAmount'] as num?)?.toDouble() ?? 0,
      monthlyGoal: (json['monthlyGoal'] as num?)?.toDouble() ?? 0,
    );
  }
}

// 설정 저장/불러오기
class SettingsStorage {
  static const String _keyStartingAmount = 'starting_amount';
  static const String _keyMonthlyGoal = 'monthly_goal';

  static Future<void> saveSettings(BudgetSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyStartingAmount, settings.startingAmount);
    await prefs.setDouble(_keyMonthlyGoal, settings.monthlyGoal);
  }

  static Future<BudgetSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return BudgetSettings(
      startingAmount: prefs.getDouble(_keyStartingAmount) ?? 0,
      monthlyGoal: prefs.getDouble(_keyMonthlyGoal) ?? 0,
    );
  }
}

// 할부 클래스
class Installment {
  final String id;
  final String title;
  final double totalAmount;
  final double monthlyAmount;
  final int totalMonths;
  int currentMonth;
  final String category;
  final DateTime startDate;

  Installment({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.monthlyAmount,
    required this.totalMonths,
    this.currentMonth = 1,
    required this.category,
    required this.startDate,
  });

  bool get isComplete => currentMonth >= totalMonths;
  int get remainingMonths => totalMonths - currentMonth;
  double get remainingAmount => monthlyAmount * remainingMonths;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'totalAmount': totalAmount,
    'monthlyAmount': monthlyAmount,
    'totalMonths': totalMonths,
    'currentMonth': currentMonth,
    'category': category,
    'startDate': startDate.toIso8601String(),
  };

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id'],
      title: json['title'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      monthlyAmount: (json['monthlyAmount'] as num).toDouble(),
      totalMonths: json['totalMonths'],
      currentMonth: json['currentMonth'] ?? 1,
      category: json['category'],
      startDate: DateTime.parse(json['startDate']),
    );
  }

  void nextMonth() {
    if (currentMonth < totalMonths) {
      currentMonth++;
    }
  }
}
final List<String> expenseCategories = [
  '식비', '교통', '쇼핑', '엔터', '주거', '의료', '교육', '기타'
];

// 수입 카테고리
final List<String> incomeCategories = [
  '월급', '상여금', '투자수익', '용돈', '환급', '기타수입'
];

// 카테고리별 아이콘
IconData getCategoryIcon(String category) {
  final iconMap = {
    // 지출
    '식비': Icons.restaurant,
    '교통': Icons.directions_bus,
    '쇼핑': Icons.shopping_bag,
    '엔터': Icons.movie,
    '주거': Icons.home,
    '의료': Icons.local_hospital,
    '교육': Icons.school,
    '기타': Icons.category,
    // 수입
    '월급': Icons.work,
    '상여금': Icons.card_giftcard,
    '투자수익': Icons.trending_up,
    '용돈': Icons.attach_money,
    '환급': Icons.reply,
    '기타수입': Icons.add_circle,
  };
  return iconMap[category] ?? Icons.category;
}

// 카테고리별 색상
Color getCategoryColor(String category) {
  final colorMap = {
    // 지출 - 다양한 색상
    '식비': const Color(0xFFFF6B6B),      // 코랄
    '교통': const Color(0xFF7B61FF),      // 볼록
    '쇼핑': const Color(0xFFFFC93C),      // 노랑
    '엔터': const Color(0xFF00D4AA),      // 민트
    '주거': const Color(0xFFFF8E53),      // 주황
    '의료': const Color(0xFF00B4D8),      // 하늘
    '교육': const Color(0xFFFF5E7D),      // 핑크
    '기타': const Color(0xFF9CA3AF),      // 회색
    // 수입 - 다양한 색상
    '월급': const Color(0xFF00D4AA),
    '상여금': const Color(0xFF7B61FF),
    '투자수익': const Color(0xFFFFC93C),
    '용돈': const Color(0xFFFF8E53),
    '환급': const Color(0xFF00B4D8),
    '기타수입': const Color(0xFFFF5E7D),
  };
  return colorMap[category] ?? Colors.grey;
}
