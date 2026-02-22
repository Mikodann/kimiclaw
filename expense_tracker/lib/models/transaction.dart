import 'package:flutter/material.dart';

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
  double startingAmount;  // 시작 금액
  double monthlyGoal;     // 이번달 목표

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
      startingAmount: json['startingAmount'] ?? 0,
      monthlyGoal: json['monthlyGoal'] ?? 0,
    );
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
    // 지출 - 빨강/주황 계열
    '식비': Colors.red,
    '교통': Colors.blue,
    '쇼핑': Colors.green,
    '엔터': Colors.orange,
    '주거': Colors.purple,
    '의료': Colors.teal,
    '교육': Colors.indigo,
    '기타': Colors.grey,
    // 수입 - 다양한 색상
    '월급': const Color(0xFF00D4AA),      // 민트
    '상여금': const Color(0xFF7B61FF),    // 볼록
    '투자수익': const Color(0xFFFFC93C),  // 노랑
    '용돈': const Color(0xFFFF8E53),      // 주황
    '환급': const Color(0xFF00B4D8),      // 하늘
    '기타수입': const Color(0xFFFF5E7D),  // 핑크
  };
  return colorMap[category] ?? Colors.grey;
}

