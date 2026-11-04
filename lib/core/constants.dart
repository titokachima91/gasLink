/// lib/core/constants.dart
/// ROLE: Single source of truth for pilot-stage fixed values.
/// Brands, sizes-per-brand, districts, order statuses (+ bilingual labels),
/// commission default. Everything here is SELECTED from, never free-typed,
/// so the database stays clean for search/routing.
/// NOTE: before public launch, brands/districts move to Firestore
/// reference collections so we can edit them without a rebuild.
class AppConstants {
  static const String appName = 'GasLink';
  static const String appNameSw = 'GasLink';

  /// Canonical brand list — vendors pick from this, never invent brands.
  static const List<String> gasBrands = [
    'Oryx Gas',
    'Taifa Gas',
    'O-Lake Gas',
    'O-Gas',
    'Puma Gas',
    'Manjis Gas',
    'Camel Gas',
  ];

  /// Pre-selected on vendor onboarding; vendor may remove them.
  static const List<String> defaultBrands = [
    'Oryx Gas',
    'Taifa Gas',
    'O-Gas',
  ];

  /// Cylinder sizes PER BRAND — a UI can never offer a size
  /// the brand doesn't manufacture (Taifa = only 3kg brand;
  /// Manjis = 40kg, not 38kg).
  static const Map<String, List<String>> brandSizes = {
    'Oryx Gas': ['6kg', '15kg', '38kg'],
    'Taifa Gas': ['3kg', '6kg', '15kg', '38kg'],
    'O-Lake Gas': ['6kg', '15kg', '38kg'],
    'O-Gas': ['6kg', '15kg', '38kg'],
    'Puma Gas': ['6kg', '15kg', '38kg'],
    'Manjis Gas': ['6kg', '15kg', '40kg'],
    'Camel Gas': ['6kg', '15kg', '38kg'],
  };

  /// Dar es Salaam pilot districts — vendor SELECTS, never free-types,
  /// so "nearest vendor" routing and admin filters stay reliable.
  static const List<String> districts = [
    'Ilala',
    'Kinondoni',
    'Temeke',
    'Ubungo',
    'Kigamboni',
  ];

  /// Order lifecycle (single source of truth):
  /// placed → seen → confirmed → on_the_way → delivered_pending → delivered → cancelled
  /// ETA is logged when the vendor starts the journey (on_the_way), not at confirmed.
  static const List<String> orderStatuses = [
    'placed',
    'seen',
    'confirmed',
    'on_the_way',
    'delivered_pending',
    'delivered',
    'cancelled',
  ];

  /// Bilingual status labels — ALL user-facing strings go through
  /// this pattern from day one (retrofitting Swahili later is painful).
  static const Map<String, Map<String, String>> statusLabels = {
    'placed': {'en': 'Placed', 'sw': 'Imewekwa'},
    'confirmed': {'en': 'Confirmed', 'sw': 'Imethibitishwa'},
    'on_the_way': {'en': 'On the way', 'sw': 'Njiani'},
    'delivered': {'en': 'Delivered', 'sw': 'Imefika'},
    'refused': {'en': 'Refused', 'sw': 'Imekataliwa'},
  };

  /// Commission (pilot only — monetization model under review,
  /// may become subscription). Stamped per order either way.
  static const double defaultCommissionRate = 0.03;

  static const String statusPlaced = 'placed';
  static const String statusConfirmed = 'confirmed';
  static const String statusOnTheWay = 'on_the_way';
  static const String statusDelivered = 'delivered';

  // ===========================================================================
  // 🟢 NEW ACCESSIBLE INTENT CATEGORY TARGETS (NO HARDCODED VALUES)
  // PRODUCT CATEGORIES (single source of truth)
  // ===========================================================================

  /// The 4 main categories the buyer sees and the vendor can offer
  static const List<String> productCategories = [
    'refill', // Gas content only
    'full_set', // Cylinder + gas
    'accessories', // Regulators, hoses, burners, etc.
    'services', // Maintenance, installation, leak test, etc.
  ];

  /// Display labels (bilingual) for the 4 categories
  static const Map<String, String> categoryLabels = {
    'refill': 'Refill (Kujaza)',
    'full_set': 'Full Set (Mtungi + Gesi)',
    'accessories': 'Accessories (Vifaa)',
    'services': 'Services (Matengenezo)',
  };

  /// Accessories the vendor can select from (can be extended later)
  static const List<String> accessoryItems = [
    'Regulator',
    'Mrija (Hose)',
    'Burner / Stove',
    'Safety Cap',
    'Stand / Base',
    'Gas Lighter',
    'Other Accessory',
  ];

  /// Services / Maintenance the vendor can select from
  static const List<String> serviceItems = [
    'Installation (Ufungaji)',
    'Leak Test (Ukaguzi wa Uvujaji)',
    'Regulator Service',
    'Hose Replacement',
    'General Maintenance',
    'Emergency Call-out',
    'Other Service',
  ];

  /// Old list kept for backward compatibility (used by home chips)
  static const List<String> consumerIntents = [
    'Refill',
    'Full Set',
    'Accessories',
    'Services',
  ];
}
