/// Modele d un contact (locataire ou proprietaire).
class Contact {
  const Contact({
    required this.id,
    required this.initials,
    required this.name,
    required this.info,
    required this.type,
  });

  final String id;
  final String initials;
  final String name;

  /// Sous-titre, ex. « Locataire · Apt. 12 »
  final String info;
  final ContactType type;

  static const List<Contact> mockList = [
    Contact(
      id: 'c1',
      initials: 'YD',
      name: 'Yacine Diop',
      info: 'Locataire · Apt. 12',
      type: ContactType.tenant,
    ),
    Contact(
      id: 'c2',
      initials: 'FN',
      name: 'Fatou Ndiaye',
      info: 'Locataire · Duplex',
      type: ContactType.tenant,
    ),
    Contact(
      id: 'c3',
      initials: 'MC',
      name: 'Mamadou Camara',
      info: 'Propriétaire · 4 biens',
      type: ContactType.owner,
    ),
    Contact(
      id: 'c4',
      initials: 'AS',
      name: 'Aïcha Sarr',
      info: 'Propriétaire · 2 biens',
      type: ContactType.owner,
    ),
    Contact(
      id: 'c5',
      initials: 'OG',
      name: 'OJO Gael',
      info: 'Locataire · Villa — Saly',
      type: ContactType.tenant,
    ),
  ];

  static int get tenantCount =>
      mockList.where((c) => c.type == ContactType.tenant).length;

  static int get ownerCount =>
      mockList.where((c) => c.type == ContactType.owner).length;
}

enum ContactType { tenant, owner }
