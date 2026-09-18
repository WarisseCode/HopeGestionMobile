class KpiItem {
  final String label;
  final String value;
  final String note;
  final bool isPositive;

  const KpiItem({
    required this.label,
    required this.value,
    required this.note,
    required this.isPositive,
  });
}

class FluxDayData {
  final int day;
  final double inAmount;
  final double outAmount;

  const FluxDayData({
    required this.day,
    required this.inAmount,
    required this.outAmount,
  });
}

class RecentRentPayment {
  final String id;
  final String property;
  final String type;
  final String tenant;
  final String amount;
  final String status;
  final String? imageUrl;

  const RecentRentPayment({
    required this.id,
    required this.property,
    required this.type,
    required this.tenant,
    required this.amount,
    required this.status,
    this.imageUrl,
  });
}

class DashboardData {
  final String userName;
  final String dateFormatted;
  final KpiItem encaissements;
  final KpiItem depenses;
  final KpiItem impayes;
  final String netFlux;
  final List<FluxDayData> fluxDays;
  final List<RecentRentPayment> recentRents;

  const DashboardData({
    required this.userName,
    required this.dateFormatted,
    required this.encaissements,
    required this.depenses,
    required this.impayes,
    required this.netFlux,
    required this.fluxDays,
    required this.recentRents,
  });

  /// Données par défaut issues de mock-data.json
  factory DashboardData.mock() {
    return const DashboardData(
      userName: 'Warisse OTCHADE',
      dateFormatted: 'LUNDI 14 AVRIL',
      encaissements: KpiItem(
        label: 'Encaiss.',
        value: '2,45 M',
        note: '+12% ce mois',
        isPositive: true,
      ),
      depenses: KpiItem(
        label: 'Dépenses',
        value: '890 K',
        note: '24% du CA',
        isPositive: false,
      ),
      impayes: KpiItem(
        label: 'Impayés',
        value: '320 K',
        note: '3 factures',
        isPositive: false,
      ),
      netFlux: '+1 560 000 F',
      fluxDays: [
        FluxDayData(day: 12, inAmount: 58, outAmount: 35),
        FluxDayData(day: 13, inAmount: 45, outAmount: 20),
        FluxDayData(day: 14, inAmount: 72, outAmount: 40),
        FluxDayData(day: 15, inAmount: 54, outAmount: 30),
        FluxDayData(day: 16, inAmount: 78, outAmount: 45),
        FluxDayData(day: 17, inAmount: 61, outAmount: 32),
        FluxDayData(day: 18, inAmount: 48, outAmount: 25),
      ],
      recentRents: [
        RecentRentPayment(
          id: '1',
          property: 'Apt. 12 — Mbour',
          type: 'Appartement T3 · 86 m²',
          tenant: 'Yacine Diop',
          amount: '185 000 F',
          status: 'Payé',
          imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=150&auto=format&fit=crop&q=80',
        ),
        RecentRentPayment(
          id: '2',
          property: 'Duplex — Almadies',
          type: 'Villa F5 · 220 m²',
          tenant: 'Fatou Ndiaye',
          amount: '450 000 F',
          status: 'En attente',
          imageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=150&auto=format&fit=crop&q=80',
        ),
        RecentRentPayment(
          id: '3',
          property: 'Local — Plateau',
          type: 'Local commercial · 65 m²',
          tenant: 'M. Camara',
          amount: '320 000 F',
          status: 'Impayé',
          imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=150&auto=format&fit=crop&q=80',
        ),
      ],
    );
  }
}
