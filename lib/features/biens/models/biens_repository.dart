import 'package:flutter/foundation.dart';

import 'bien.dart';

/// Source de vérité unique pour la liste des biens, partagée par tous les
/// écrans. Un [ChangeNotifier] suffit ici : pas besoin d'un package de state
/// management pour un flux add-only + notify.
class BiensRepository extends ChangeNotifier {
  BiensRepository._() : _items = List.of(Bien.mockList);

  static final BiensRepository instance = BiensRepository._();

  final List<Bien> _items;

  List<Bien> get items => List.unmodifiable(_items);

  /// Ajoute un nouveau bien en tête de liste et notifie les écrans à l'écoute.
  void add(Bien bien) {
    _items.insert(0, bien);
    notifyListeners();
  }
}
