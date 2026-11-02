class ProfitLossLogic {
  static Map<String, double> calculate({
    required double costPrice,
    required double sellingPrice,
  }) {
    double profit = sellingPrice - costPrice;
    double profitPercent = costPrice > 0 ? (profit / costPrice) * 100 : 0;
    double marginPercent = sellingPrice > 0 ? (profit / sellingPrice) * 100 : 0;

    return {
      'profit': profit,
      'profitPercent': profitPercent,
      'marginPercent': marginPercent,
    };
  }

  static double calculateDiscount(
      double originalPrice, double discountPercent) {
    return originalPrice * (discountPercent / 100);
  }
}
