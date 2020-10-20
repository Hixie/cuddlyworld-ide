import 'package:flutter/foundation.dart';

abstract class Atom extends ChangeNotifier {
  final ValueNotifier<String> name = ValueNotifier<String>(null);

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }
}

class Thing extends Atom {
}

class Location extends Atom {
}