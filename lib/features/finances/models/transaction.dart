/// Modèle représentant une transaction financière (encaissement ou dépense).
class FinanceTransaction {
  final String id;
  final String title;
  final String subtitle;
  final int amount; // En FCFA (positif = entrée, négatif = sortie)
  final bool isIncome;
  final DateTime date;
  final String? category;

  const FinanceTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.date,
    this.category,
  });

  /// Formate le montant : "+185 000 F" ou "-45 000 F"
  String get formattedAmount {
    final prefix = isIncome ? '+' : '-';
    final absVal = amount.abs().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
    return '$prefix$absVal F';
  }

  /// Données de démonstration basées sur la maquette 05-finances.png
  static List<FinanceTransaction> get mockList => [
    FinanceTransaction(
      id: 'tx-1',
      title: 'Loyer reçu',
      subtitle: 'Yacine Diop',
      amount: 185000,
      isIncome: true,
      date: DateTime(2026, 4, 12),
      category: 'Loyer',
    ),
    FinanceTransaction(
      id: 'tx-2',
      title: 'Réparation plomberie',
      subtitle: 'Apt. 12',
      amount: -45000,
      isIncome: false,
      date: DateTime(2026, 4, 10),
      category: 'Maintenance',
    ),
    FinanceTransaction(
      id: 'tx-3',
      title: 'Loyer reçu',
      subtitle: 'Fatou Ndiaye',
      amount: 450000,
      isIncome: true,
      date: DateTime(2026, 4, 8),
      category: 'Loyer',
    ),
    FinanceTransaction(
      id: 'tx-4',
      title: 'Honoraires gardiennage',
      subtitle: 'Résidence Les Palmiers',
      amount: -80000,
      isIncome: false,
      date: DateTime(2026, 4, 5),
      category: 'Charges',
    ),
    FinanceTransaction(
      id: 'tx-5',
      title: 'Loyer reçu',
      subtitle: 'Kouassi Mensah',
      amount: 220000,
      isIncome: true,
      date: DateTime(2026, 4, 2),
      category: 'Loyer',
    ),
  ];
}

/// Métriques financières globales
class FinanceMetrics {
  final String period;
  final String availableBalance;
  final String totalIncome;
  final String totalExpenses;

  const FinanceMetrics({
    required this.period,
    required this.availableBalance,
    required this.totalIncome,
    required this.totalExpenses,
  });

  static const FinanceMetrics mock = FinanceMetrics(
    period: 'AVRIL 2026',
    availableBalance: '1 560 000 F',
    totalIncome: '+2,45 M',
    totalExpenses: '-890 K',
  );
}
