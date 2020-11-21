import 'package:flutter/material.dart';

import 'atom_widget.dart';
import 'backend.dart';
import 'data_model.dart';
import 'dialogs.dart';
import 'disposition.dart';

class Cart extends StatefulWidget {
  const Cart({
    Key key,
    @required this.game,
  }) : super(key: key);

  final CuddlyWorld game;

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  String _message;

  void _updateMessage() {
    final Set<Atom> atoms = EditorDisposition.of(context).cart;
    final Set<Atom> history = <Atom>{};
    final String command = <String> [
       ...atoms.map((Atom atom) => atom.encodeForServerMake(history)),
       ...atoms.map((Atom atom) => atom.encodeForServerConnect()),
    ].join('; ');
    setState(() {
      _message = 'debug make \'${escapeSingleQuotes(command)}\'';
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMessage();
  }

  void _sendToServer() async {
    final Set<Atom> atoms = EditorDisposition.of(context).cart;
    if(atoms.isEmpty) 
      return;
    String heading;
    if (atoms.length == 1)
      heading = 'Adding ${atoms.single.identifier.identifier} to world';
    else
      heading = 'Adding ${atoms.length} atoms to world';
    try {
      final String reply = await widget.game.sendMessage(_message);
      if (mounted)
        await showMessage(context, heading, reply);
    } on ConnectionLostException {
      if (mounted)
        await showMessage(context, heading, 'Conection lost');
    }
  }

  Set<Atom> expand(Set<Atom> cart) {
    final Set<Atom> pending = cart.toSet();
    final Set<Atom> results = <Atom>{};
    while (pending.isNotEmpty) {
      final Atom next = pending.first;
      pending.remove(next);
      if (!results.contains(next)) {
        results.add(next);
        pending.addAll(next.children);
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final Set<Atom> cart = EditorDisposition.of(context).cart;
    final List<Atom> atoms = expand(cart).toList()..sort();
    return SizedBox.expand(
      child: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 48.0, left: 24.0, right: 24.0, bottom: 24.0),
                constraints: const BoxConstraints(
                  maxWidth: 400.0,
                ),
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: const BorderSide(width: 0.0, color: Color(0xFFD0D0D0)),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0x00FFFFFF),
                      Color(0x10000000),
                      Color(0x00FFFFFF),
                    ],
                    stops: <double>[
                      0.0,
                      0.2,
                      1.0,
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: ListBody(
                  children: <Widget>[
                    for (final Atom atom in atoms)
                      Padding(
                        padding: EdgeInsets.only(
                          top: atom.parent != null ? 4.0 : 16.0,
                          left: 16.0 * atom.depth,
                          bottom: 4.0,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AtomWidget(
                            icon: cart.contains(atom) ? const Icon(Icons.shopping_cart, size: 18.0) : null,
                            atom: atom,
                            onTap: () {
                              EditorDisposition.of(context).current = atom;
                            },
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 48.0, bottom: 8.0),
                      child: Center(
                        child: OutlinedButton(
                          onPressed: _sendToServer,
                          child: const Text('Send to server'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8.0),
              padding: const EdgeInsets.all(8.0),
              child: ListBody(
                children: <Widget>[
                  Text('Command', style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.grey.shade600)),
                  SelectableText(_message, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}