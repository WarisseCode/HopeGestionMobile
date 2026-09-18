/// Modele d un bien immobilier affiche dans la liste.
class Bien {
  const Bien({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.status,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String type;
  final String price;
  final BienStatus status;
  final String? imageUrl;

  static const List<Bien> mockList = [
    Bien(
      id: 'prop-1',
      name: 'Apt. 12 — Mbour',
      type: 'Appartement T3 · 86 m²',
      price: '185 000 F / mois',
      status: BienStatus.occupe,
    ),
    Bien(
      id: 'prop-2',
      name: 'Duplex — Almadies',
      type: 'Villa F5 · 220 m²',
      price: '450 000 F / mois',
      status: BienStatus.occupe,
    ),
    Bien(
      id: 'prop-3',
      name: 'Local — Plateau',
      type: 'Local commercial · 65 m²',
      price: '320 000 F / mois',
      status: BienStatus.vacant,
    ),
    Bien(
      id: 'prop-4',
      name: 'Villa — Saly',
      type: 'Villa F6 · 350 m²',
      price: '650 000 F / mois',
      status: BienStatus.occupe,
    ),
    Bien(
      id: 'prop-5',
      name: 'Studio — Dakar Plateau',
      type: 'Studio · 28 m²',
      price: '90 000 F / mois',
      status: BienStatus.vacant,
    ),
  ];
}

enum BienStatus {
  occupe,
  vacant;

  String get label {
    switch (this) {
      case BienStatus.occupe:
        return 'OCCUPÉ';
      case BienStatus.vacant:
        return 'VACANT';
    }
  }
}
