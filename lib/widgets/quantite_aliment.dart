import 'package:flutter/material.dart';
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
  
  double? calories;
  double? proteines;
  double? lipides;
  double? glucides;

  Portion? portionChoisie;
  double quantite = 100;

  // Portion spéciale pour "Grammes"
  late Portion portionGrammes;

  List<Portion> get portionsAvecGrammes {
    if (widget.aliment.portions.isEmpty) {
    // Si aucune portion dans la base, on ne retourne que la portionGrammes
    return [portionGrammes];
  }
  // Sinon, on retourne la portionGrammes + toutes les autres
    return [portionGrammes, ...widget.aliment.portions];
  }  


  @override
  void initState() {
    super.initState();

    // Portion spéciale "Grammes" pour entrée manuelle
    portionGrammes = Portion(nom: "g", poids: quantite);

    if (widget.aliment.portions.isNotEmpty) {
    // Ici tu choisis la première portion de la liste comme "par défaut"
    portionChoisie = widget.aliment.portions.first;

    // Quantité par défaut = 1 portion
    quantite = 1;
  } else {
    // Si aucune portion : on met "Grammes" à 100g
    portionChoisie = portionGrammes;
    quantite = 100;
  }
    
    // Init du contrôleur avec la quantité par défaut
    quantiteController = TextEditingController(text: quantite.toString());
    quantiteFocusNode = FocusNode(); // ✅ init

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
    });
    } else {
      // Autres portions : 1 portion par défaut
    setState(() {
      double portionPoids = portionChoisie!.poids; // poids en grammes de la portion
      calories = (widget.aliment.calories * portionPoids * quantite) / 100;
      proteines = (widget.aliment.proteines * portionPoids * quantite) / 100;
      lipides = (widget.aliment.lipides * portionPoids * quantite) / 100;
      glucides = (widget.aliment.glucides * portionPoids * quantite) / 100;
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
  static const double champsQfontSize = 14;

  @override
  void dispose() {
    quantiteController.dispose();
    quantiteFocusNode.dispose(); // ✅ libération du focus node    
    super.dispose();
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
            
      backgroundColor: const Color(0xFF393939),
      body: SafeArea(
        child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(40), // 16
        child: Column(
                    
          children: [

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

              IconButton(
              icon: const Icon(Icons.chevron_left, 
              color: Colors.white,
              size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
              ),

              Expanded(
              child: Text(widget.aliment.nom.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  overflow: TextOverflow.ellipsis, // Ajoute "..." si ça dépasse
                  ),
                  softWrap: true, // Autorise le retour à la ligne
                  maxLines: 2,
                    ),
                ),    // Nombre maximum de lignes (à ajuster)),
              ],
            ),

            const SizedBox(height: 24),

            Row(mainAxisAlignment: MainAxisAlignment.start,
            
              children: [
              _buildResult("Calories", calories, unit: "kcal")              
            ]
            ),

            const SizedBox(height: 20),
            
            SizedBox(
              height: 1,
              width: 285,
              child: Container(
                color: Color(0x3FFFFFFF),
              )                            
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResult("Protéines", proteines, unit: "g"),
                _buildResult("Lipides", lipides, unit: "g"),
                _buildResult("Glucides", glucides, unit: "g"),
              ],
            ),
            
            

            const SizedBox(height: 24),
            
            Container(                      
            width: 260,            
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
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
          ],
        ),
      ),
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
            controller.text = quantite.toString(); // dernière valeur valide
          });
        }
      }
    },     
    
    child: TextField(
      cursorHeight: champsQheight * 0.8,
      cursorColor: Color(0xFF357E50),
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: champsQfontSize),
      textAlign: TextAlign.right,
      textAlignVertical: TextAlignVertical.center,

      // ✅ Quand l’utilisateur clique dans le champ, on efface la valeur
      onTap: () {
        controller.clear();
        _buildOperatorsRow;
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
            return 'Portion (${p.poids} g)';
            } else if (p.nom == 'g') {
              return p.nom;              
            } else {
              return '${p.nom} (${p.poids} g)';
            }

            }(),
            style: const TextStyle(color: Colors.white, fontSize: champsQfontSize),
          ),
          ),

        );
      }).toList(),
      
      onChanged: (Portion? nouvellePortion) {
        
        if (nouvellePortion == null) return;        
        setState(() {
          portionChoisie = nouvellePortion;
          
          if (portionChoisie!.nom == "g") {
          quantite = 100;          
          } else {
            quantite = 1; // valeur par défaut pour les autres portions
          }
          
          quantiteController.text = quantite.toString();
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

  Widget _buildOperatorsRow() {
    final ops = ['+', '-', '*', '/'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ops.map((op) {
        return ElevatedButton(
          onPressed: () {
            final text = quantiteController.text;
            quantiteController.text = "$text$op";
            quantiteController.selection = TextSelection.fromPosition(
              TextPosition(offset: quantiteController.text.length),
            );
          },
          child: Text(op),
        );
      }).toList(),
    );
  }


}