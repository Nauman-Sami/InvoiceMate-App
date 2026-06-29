class AppConstants {
  static const String appName = 'InvoiceMate';

  // Hive Box Names
  static const String invoiceBox = 'invoices';
  static const String clientBox = 'clients';
  static const String productBox = 'products';
  static const String profileBox = 'profile';
  static const String settingsBox = 'settings';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String invoicesCollection = 'invoices';
  static const String clientsCollection = 'clients';
  static const String productsCollection = 'products';

  // Invoice Statuses
  static const String statusDraft = 'Draft';
  static const String statusSent = 'Sent';
  static const String statusPaid = 'Paid';
  static const String statusOverdue = 'Overdue';
  static const String statusCancelled = 'Cancelled';

  // Sync Status
  static const String syncPending = 'pending';
  static const String syncSynced = 'synced';
}
