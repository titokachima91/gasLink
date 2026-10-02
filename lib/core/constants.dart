class AppConstants {
  static const String appName = 'GasLink';
  static const String appNameSw = 'GasLink';
  static const List<String> gasBrands = [
    'Oryx Gas',
    'Taifa Gas',
    'O-Lake Gas',
    'O-Gas',
    'Puma Gas',
    'Manjis Gas',
    'Camel Gas'
  ];
  static const List<String> cylinderSizes = [
    '3kg',
    '6kg',
    '10kg',
    '15kg',
    '38kg'
  ];
  static const List<String> orderStatuses = [
    'placed',
    'confirmed',
    'on_the_way',
    'delivered',
    'refused',
  ];
  static const Map<String, Map<String, String>> statusLabels = {
    'placed': {'en': 'Placed', 'sw': 'Imewekwa'},
    'confirmed': {'en': 'Confirmed', 'sw': 'Imethibitishwa'},
    'on_the_way': {'en': 'On the way', 'sw': 'Njiani'},
    'delivered': {'en': 'Delivered', 'sw': 'Imefika'},
    'refused': {'en': 'Refused', 'sw': 'Imekataliwa'},
  };
  static const double defaultCommissionRate = 0.03;
  // Order status flow: placed → confirmed → on_the_way → delivered
  static const String statusPlaced = 'placed';
  static const String statusConfirmed = 'confirmed';
  static const String statusOnTheWay = 'on_the_way';
  static const String statusDelivered = 'delivered';
}
