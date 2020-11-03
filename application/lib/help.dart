import 'package:flutter/material.dart';

class HelpTab extends StatefulWidget {
  const HelpTab({Key key}) : super(key: key);

  @override
  _HelpTabState createState() => _HelpTabState();
}

class _HelpTabState extends State<HelpTab>{

  @override
  Widget build(BuildContext context) {
    return ListView(
          children: <Widget>[
            Text('Introduction', style: Theme.of(context).textTheme.headline4),
            const Text(
                "To create a TAtom from scratch, go to the 'editor' tab and press the plus button. "
                'Then edit the fields.\n'
                "To add something to the world, press 'add to cart', then go to cart and press send to server."
              ),
            Text('\nFields', style: Theme.of(context).textTheme.headline4),
            const Text(
              'There are different kinds of fields:\n'
              '- text fields, like name, identifer, pattern, description\n'
              '- dropdown fields, like class, position, size, mass\n'
              '- atom fields, like source, door side, where you drag the atom to the field\n'
              '- children field, which has dropdown and atom fields\n'
              '- landmark field, which has dropdown and atom fields\n'
            ),
            Text('Patterns', style: Theme.of(context).textTheme.headline4),
            const Text("""Nested lists are marked by round brackets (...).                                                                                                         
   Tokens can have a "+" suffix indicating that the token can be repeated.                                                                                  
   Tokens can have a "?" suffix indicating that the token can be omitted.                                                                                   
   Nested lists can have suffixes to indicate what kind of list it is:                                                                                      
     (a b c)   - sequence list (all tokens must appear in order)                                                                                            
     (a b c)?  - optional sequence list (if any appear, they must all appear, in order)                                                                     
     (a b c)@  - alternatives (one of the tokens must appear)                                                                                               
     (a b c)*  - zero or more of the alternatives must appear, in any order                                                                                 
     (a b c)#  - one or more of the alternatives must appear, in any order                                                                                  
     (a b c)%  - zero or more of the alternatives must appear, but they must be in the order given                                                          
     (a b c)&  - one or more of the alternatives must appear, but they must be in the order given                                                           
   Tokens and nested lists can be split with a "/" to indicate alternative singular/plural forms.                                                           
   Tokens and nested lists can be suffixed (after the suffixes mentioned above) with ":" and an                                                             
   integer in the range 0..31 to indicate a flag that must be matched for that token or list to be                                                          
   considered. Flag indices are zero-based. (TMatcherFlags' least-significant-bit corresponds to                                                            
   flag zero, the second bit corresponds to flag 1, and so forth.)                                                                                          
   Special characters can be escaped using \.                                                                                                               
                                                                                                                                                          
   Examples:                                                                                                                                                
     'a b c' - only matched by "a b c"                                                                                                                      
                                                                                                                                                          
     'the? ((glowing green)# lantern/lanterns)&' - returns a singular matcher that matches:                                                                 
         "the glowing", "the green", "the lantern",                                                                                                         
         "the glowing green", "the glowing lantern", "the green lantern",                                                                                   
         "the glowing green lantern", and all of those again without "the"                                                                                  
     ...and a plural matcher that matches the same but with "lanterns" instead of "lantern".                                                                
                                                                                                                                                          
     '(two beads)/bead' - returns a matcher that matches "two beads" and                                                                                    
     a matcher that matches "bead".                                                                                                                         
                                                                                                                                                          
     'the? burning:0 bush' - returns a matcher that matches either:                                                                                         
       'the burning bush' and 'burning bush' when flag 0 is set                                                                                             
       just 'the bush' and 'bush' when flag 0 is not set                       """),
          ],
        );
  }
}
