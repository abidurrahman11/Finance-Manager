class AppConstants {
  static const String baseUrl =
      'https://finance-manager-backend-wllu.onrender.com/api';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // Expense Categories
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Health & Medical',
    'Housing',
    'Utilities',
    'Education',
    'Travel',
    'Personal Care',
    'Gifts & Donations',
    'Investments',
    'Other',
  ];

  // Income Categories
  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Investment Returns',
    'Rental Income',
    'Bonus',
    'Gift',
    'Refund',
    'Other',
  ];
}
