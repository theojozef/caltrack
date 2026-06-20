import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/aliment.dart';
import 'package:math_expressions/math_expressions.dart';


class QuantiteAliment extends StatefulWidget {
  //final String nom;
  //final double calories;
  //final double proteines;
  //final double lipides;
  //final double glucides;
  final Aliment aliment;

  const QuantiteAliment({
    super.key,
    //required this.nom,
    //required this.calories,
    //required this.proteines,
    //required this.lipides,
    //required this.glucides,
    required this.aliment,
  }); 

  @override
  State<QuantiteAliment> createState() => _QuantiteAlimentState();
}


class _QuantiteAlimentState extends State<QuantiteAliment> {
  
  late TextEditingController quantiteController;
  late FocusNode quantiteFocusNode; // ✅ focus node pour le champ quantité
  late ScrollController _scrollController;

  String _fmtQty(double q) => q == q.roundToDouble() ? q.round().toString() : q.toStringAsFixed(1);
  
  double? calories;
  double? proteines;
  double? lipides;
  double? glucides;
  double? fibres;

  Portion? portionChoisie;
  double quantite = 100;

  // Portion spéciale pour "Grammes"
  late Portion portionGrammes;

  // Ignore une portion unique à 100g (identique au défaut grammes → doublon inutile)
  List<Portion> get _portionsReelles {
    if (widget.aliment.portions.length == 1 && widget.aliment.portions.first.poids == 100) {
      return [];
    }
    return widget.aliment.portions;
  }

  List<Portion> get portionsAvecGrammes {
    if (_portionsReelles.isEmpty) {
      return [portionGrammes];
    }
    return [portionGrammes, ..._portionsReelles];
  }


  @override
  void initState() {
    super.initState();

    // Portion spéciale "Grammes" pour entrée manuelle
    portionGrammes = Portion(nom: "g", poids: quantite);

    if (_portionsReelles.isNotEmpty) {
    portionChoisie = _portionsReelles.first;
    quantite = 1;
  } else {
    portionChoisie = portionGrammes;
    quantite = 100;
  }
    
    // Init du contrôleur avec la quantité par défaut
    quantiteController = TextEditingController(text: _fmtQty(quantite));
    quantiteFocusNode = FocusNode(); // ✅ init
    _scrollController = ScrollController();

    // Calcul initial
    _recalculerMacros(quantite);
  }

  void _recalculerMacros(double quantite) {
    if (portionChoisie!.nom == "g") {
    // Portion en grammes : calcul classique
    setState(() {
      calories = (widget.aliment.calories * quantite) / 100;
      proteines = (widget.aliment.proteines * quantite) / 100;
      lipides = (widget.aliment.lipides * quantite) / 100;
      glucides = (widget.aliment.glucides * quantite) / 100;
      fibres = (widget.aliment.fibres * quantite) / 100;
    });
    } else {
      // Autres portions : 1 portion par défaut
    setState(() {
      double portionPoids = portionChoisie!.poids; // poids en grammes de la portion
      calories = (widget.aliment.calories * portionPoids * quantite) / 100;
      proteines = (widget.aliment.proteines * portionPoids * quantite) / 100;
      lipides = (widget.aliment.lipides * portionPoids * quantite) / 100;
      glucides = (widget.aliment.glucides * portionPoids * quantite) / 100;
      fibres = (widget.aliment.fibres * portionPoids * quantite) / 100;
    });
    }
  }

  void _validerModifications() {
    Navigator.pop(context, {
      'quantite': double.tryParse(quantiteController.text) ?? 100,
      'portionChoisie': portionChoisie,  // Ajout de la quantité
      //'calories': calories ?? 0,
      //'proteines': proteines ?? 0,
      //'lipides': lipides ?? 0,
      //'glucides': glucides ?? 0,
    });
  }
  
  // VARIABLES
  static const double champsQheight = 31;
  static const double champsQfontSize = 12;
  static const Set<String> _operateurs = {'+', '−', '×', '÷'};

  @override
  void dispose() {
    quantiteController.dispose();
    quantiteFocusNode.dispose(); // ✅ libération du focus node
    _scrollController.dispose();
    super.dispose();
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final bool barreVisible = keyboardHeight > 0;
    const double barreHauteur = 48;

    return Scaffold(

      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF393939),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                bottom: barreVisible ? barreHauteur + 12 : 40,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(

          children: [

            const SizedBox(height: 24), //TOP ECRAN

            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                  padding: EdgeInsets.zero,
                  onPressed: () { Navigator.pop(context); },
                ),
              ],
            ),

            const SizedBox(height: 10), //entre chevron et nom aliment

            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  widget.aliment.nom.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  softWrap: true,
                  maxLines: 2,
                ),
              ),
            ),

            const SizedBox(height: 18), //sous nom aliment

            Center(
              child: SizedBox(
                width: 260,
                child: Container(height: 1, color: const Color(0x3FFFFFFF)),
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: Column(
                children: [
                  Text(
                    calories?.toStringAsFixed(0) ?? '0',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "CALORIES • kcal",
                    style: TextStyle(
                      color: Color(0x88FFFFFF),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: SizedBox(
                width: 260,
                child: Container(height: 1, color: const Color(0x3FFFFFFF)),
              ),
            ),

            const SizedBox(height: 18), //au dessus macros

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildResult("Protéines", proteines, unit: "g"),
                _buildResult("Lipides", lipides, unit: "g"),
                _buildResult("Glucides", glucides, unit: "g"),
                _buildResult("Fibres", fibres, unit: "g"),
              ],
            ),

            const SizedBox(height: 32),

            // Container PORTION dans le flux de la page
            Center(
              child: Container(
                width: 260,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF393939),
                  border: Border.all(color: Color(0x3B000000)),
                  borderRadius: BorderRadius.circular(25),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                  const Text("PORTION",
                  style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [

                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: champsQheight,
                      width: 80,
                      child: _buildQuantiteInput("", quantiteController),
                  ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: champsQheight,
                      width: 125,
                      child: _buildPortionDropdown(),
                  ),
                  ),

                  ],
                  ),

                  const SizedBox(height: 12),

                  //BOUTON DE VALIDATION
                  SizedBox(
                    width: 222,
                    height: 50,
                  child: ElevatedButton(

                      onPressed: _validerModifications,

                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15), // optionnel : coins arrondis
                          ),

                        backgroundColor: const Color(0xFF357E50),
                        padding: const EdgeInsets.symmetric(vertical: 14),

                      ),
                      child: const Text(
                        "Ajouter",
                        style: TextStyle(fontSize: 16,
                        color: Colors.white),
                        ),
                  ),
                  ),
                  ],
                ),
              ),
            ),

          ],
                ),
              ),
            ),
          ),

          if (barreVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildOperatorsBar(),
            ),
        ],
        ),
      ),
    );
  }


  //CHAMPS QUANTITE
  Widget _buildQuantiteInput(String label, TextEditingController controller) {
    
    return Focus(
    focusNode: quantiteFocusNode,
    onFocusChange: (hasFocus) {
      if (!hasFocus) {
        // Quand on quitte le champ
        if (controller.text.trim().isEmpty) {
          setState(() {
            controller.text = _fmtQty(quantite); // dernière valeur valide
          });
        }
      }
    },     
    
    child: TextField(
      cursorHeight: champsQheight / 2,
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-−×÷., ]'))],
      style: const TextStyle(color: Colors.white, fontSize: champsQfontSize),
      textAlign: TextAlign.right,
      textAlignVertical: TextAlignVertical.center,

      // ✅ Quand l’utilisateur clique dans le champ, on efface la valeur
      onTap: () {
        controller.clear();
        Future.delayed(const Duration(milliseconds: 350), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      },      
      
      onChanged: (value) {
        if (value.trim().isEmpty) return;

  try {
    // Parser l’expression
    final parser = ShuntingYardParser();
    Expression exp = parser.parse(value);
    ContextModel cm = ContextModel();

    // Calcul du résultat
    double resultat = exp.evaluate(EvaluationType.REAL, cm);

    setState(() {
      quantite = resultat;
      _recalculerMacros(quantite);
    });

  } catch (e) {
    // Si erreur de syntaxe, on ne fait rien
        }
      },

      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),

        // isDense: true, // permet de réduire la hauteur tout en centrant le texte
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: champsQfontSize/2),
        
        //NON CLIQUÉ
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0x3B000000)),
          borderRadius: BorderRadius.circular(25),
        ),
        
        
        //CLIQUÉ
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0x3B000000)),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    ),
    );
  }

  //CHAMPS PORTION
  Widget _buildPortionDropdown() {
    return DropdownButtonFormField<Portion>(
      value: portionChoisie,      
      items: portionsAvecGrammes.map((p) {
        return DropdownMenuItem<Portion>(
          value: p,
          
          child: Align(alignment: Alignment.centerLeft,
          child: Text((){
            if (p.nom.isEmpty) {
            return 'Portion (${p.poids.round()} g)';
            } else if (p.nom == 'g') {
              return p.nom;
            } else {
              return '${p.nom} (${p.poids.round()} g)';
            }

            }(),
            style: const TextStyle(color: Colors.white, fontSize: champsQfontSize),
          ),
          ),

        );
      }).toList(),
      
      onChanged: _portionsReelles.isEmpty ? null : (Portion? nouvellePortion) {
        
        if (nouvellePortion == null) return;        
        setState(() {
          portionChoisie = nouvellePortion;
          
          if (portionChoisie!.nom == "g") {
          quantite = 100;          
          } else {
            quantite = 1; // valeur par défaut pour les autres portions
          }
          
          quantiteController.text = _fmtQty(quantite);
          _recalculerMacros(quantite);
        });
      
      },

      decoration: InputDecoration(
        //labelText: "Portion",
        labelStyle: const TextStyle(color: Colors.white),

        contentPadding: const EdgeInsets.only(left: champsQheight/3),
        
        //NON CLIQUÉ
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0x3B000000)),
          borderRadius: BorderRadius.circular(25),
        ),
        
        //CLIQUÉ
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0x3B000000)),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      icon: _portionsReelles.isEmpty
          ? const SizedBox.shrink()
          : const Icon(Icons.arrow_drop_down),
      dropdownColor: const Color(0xFF393939),
      style: const TextStyle(color: Colors.white),
      
    );
  }


  Widget _buildResult(String label, double? value, {String unit = ''}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      
      children: [
        
        Text(
        label,
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 11,
          fontWeight: FontWeight.bold
          ),
        ),

        Text(
        "${value?.toStringAsFixed(1) ?? '0'} $unit",
        style: const TextStyle(
          color: Color(0xBAFFFFFF), 
          fontSize: 11          
        ),
        ),      
      ],
      )
      
      
    );
  }

  Widget _buildOperatorsBar() {
    return Material(
      color: const Color(0xFF2B2B2B),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            const Spacer(),
            _opButton('+'),
            _opButton('−'),
            _opButton('×'),
            _opButton('÷'),
            Container(width: 1, color: const Color(0x88FFFFFF)),
            SizedBox(
              width: 64,
              child: InkWell(
                onTap: _evaluerExpression,
                child: const Center(
                  child: Text(
                    '=',
                    style: TextStyle(
                      color: Color(0xFF357E50),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _opButton(String symbole) {
    return SizedBox(
      width: 52,
      child: InkWell(
        onTap: () {
          final texte = quantiteController.text.trimRight();
          if (texte.isNotEmpty && _operateurs.contains(texte[texte.length - 1])) return;
          quantiteController.text = '$texte $symbole ';
          quantiteController.selection = TextSelection.fromPosition(
            TextPosition(offset: quantiteController.text.length),
          );
        },
        child: Center(
          child: Text(
            symbole,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }

  void _evaluerExpression() {
    final text = quantiteController.text.trim();
    if (text.isEmpty) return;
    try {
      final texteCalc = text.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('−', '-');
      final parser = ShuntingYardParser();
      Expression exp = parser.parse(texteCalc);
      ContextModel cm = ContextModel();
      double resultat = exp.evaluate(EvaluationType.REAL, cm);
      setState(() {
        quantite = resultat;
        quantiteController.text = _fmtQty(resultat);
        quantiteController.selection = TextSelection.fromPosition(
          TextPosition(offset: quantiteController.text.length),
        );
        _recalculerMacros(quantite);
      });
    } catch (e) {
      // expression invalide, on ne fait rien
    }
  }


}