import 'package:flutter/material.dart';

class CategoryUtils {
  static IconData getExpenseIcon(String category) {
    switch (category) {
      case 'Food & Dining':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_bus;
      case 'Shopping':
        return Icons.shopping_cart;
      case 'Entertainment':
        return Icons.movie;
      case 'Health & Medical':
        return Icons.medical_services;
      case 'Housing':
        return Icons.home;
      case 'Utilities':
        return Icons.settings;
      case 'Education':
        return Icons.school;
      case 'Travel':
        return Icons.flight;
      case 'Personal Care':
        return Icons.spa_outlined;
      case 'Gifts & Donations':
        return Icons.card_giftcard;
      case 'Investments':
        return Icons.trending_up;
      case 'Other':
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  static IconData getIncomeIcon(String category) {
    switch (category) {
      case 'Salary':
        return Icons.account_balance_wallet;
      case 'Freelance':
        return Icons.computer;
      case 'Business':
        return Icons.business;
      case 'Investment Returns':
        return Icons.show_chart;
      case 'Rental Income':
        return Icons.real_estate_agent;
      case 'Bonus':
        return Icons.redeem;
      case 'Gift':
        return Icons.card_giftcard;
      case 'Refund':
        return Icons.assignment_return;
      case 'Other':
      default:
        return Icons.savings_outlined;
    }
  }
}
