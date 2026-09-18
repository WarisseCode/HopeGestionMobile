import 'package:flutter/foundation.dart';

import 'contact.dart';

/// Source de vérité unique pour la liste des contacts (locataires et
/// propriétaires), partagée par tous les écrans.
class ContactsRepository extends ChangeNotifier {
  ContactsRepository._() : _items = List.of(Contact.mockList);

  static final ContactsRepository instance = ContactsRepository._();

  final List<Contact> _items;

  List<Contact> get items => List.unmodifiable(_items);

  int get tenantCount =>
      _items.where((c) => c.type == ContactType.tenant).length;

  int get ownerCount => _items.where((c) => c.type == ContactType.owner).length;

  /// Ajoute un nouveau contact en tête de liste et notifie les écrans à l'écoute.
  void add(Contact contact) {
    _items.insert(0, contact);
    notifyListeners();
  }
}
