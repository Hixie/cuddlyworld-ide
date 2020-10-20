import 'package:flutter/foundation.dart';

abstract class Atom extends ChangeNotifier {
  String get kindDescription;

  final ValueNotifier<String> name = ValueNotifier<String>(null);

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }
}

class Thing extends Atom {
  @override
  String get kindDescription => 'Thing';
}

class Location extends Atom {
  @override
  String get kindDescription => 'Location';
}