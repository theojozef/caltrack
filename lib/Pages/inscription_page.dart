import 'package:cal_track_v1/Pages/donnees_utilisateur.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nomController = TextEditingController();
  final prenomController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;

  static const double fieldWidth = 300;
  static const double fieldHeight = 40;
  static const double gap = 15;
  static const double arrondi = 10;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nomController.dispose();
    prenomController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': emailController.text.trim(),
        'nom': nomController.text.trim(),
        'prenom': prenomController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DonneesUtilisateurPage(fromInscription: true)),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = "Un compte existe déjà avec cet email.";
            break;
          case 'weak-password':
            _errorMessage = "Mot de passe trop faible (6 caractères min.).";
            break;
          case 'invalid-email':
            _errorMessage = "Adresse email invalide.";
            break;
          default:
            _errorMessage = e.message ?? "Une erreur est survenue.";
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      filled: true,
      fillColor: const Color(0x0CFFFFFF),
      labelText: label,
      labelStyle: const TextStyle(color: Color(0x4CFFFFFF)),
      floatingLabelStyle: const TextStyle(color: Colors.white),
      prefixIcon: Icon(icon, color: const Color(0x80000000)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(arrondi),
        borderSide: const BorderSide(color: Color(0xFF357E50), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(arrondi),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(arrondi),
        borderSide: const BorderSide(color: Color(0xFF357E50), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(arrondi),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(arrondi),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF393939),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: fieldWidth,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF393939),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Bouton retour
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Créer un compte',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),

                  const SizedBox(height: 24),

                  // Prénom
                  SizedBox(
                    width: fieldWidth,
                    height: fieldHeight,
                    child: TextFormField(
                      controller: prenomController,
                      textAlignVertical: TextAlignVertical.center,
                      textCapitalization: TextCapitalization.words,

                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDecoration('Prénom', Icons.person_outline),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                    ),
                  ),

                  const SizedBox(height: gap),

                  // Nom
                  SizedBox(
                    width: fieldWidth,
                    height: fieldHeight,
                    child: TextFormField(
                      controller: nomController,
                      textAlignVertical: TextAlignVertical.center,
                      textCapitalization: TextCapitalization.words,

                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDecoration('Nom', Icons.badge_outlined),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                    ),
                  ),

                  const SizedBox(height: gap),

                  // Email
                  SizedBox(
                    width: fieldWidth,
                    height: fieldHeight,
                    child: TextFormField(
                      controller: emailController,
                      textAlignVertical: TextAlignVertical.center,
                      keyboardType: TextInputType.emailAddress,

                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDecoration('votre@email.com', Icons.email),
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                  ),

                  const SizedBox(height: gap),

                  // Mot de passe
                  SizedBox(
                    width: fieldWidth,
                    height: fieldHeight,
                    child: TextFormField(
                      controller: passwordController,
                      textAlignVertical: TextAlignVertical.center,
                      obscureText: _obscurePassword,

                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDecoration('motdepasse', Icons.lock).copyWith(
                        suffixIcon: Listener(
                          onPointerDown: (_) => setState(() => _obscurePassword = false),
                          onPointerUp: (_) => setState(() => _obscurePassword = true),
                          child: const Icon(Icons.visibility_outlined, color: Colors.grey, size: 18),
                        ),
                      ),
                      validator: (v) => v != null && v.length < 6 ? '6 caractères minimum' : null,
                    ),
                  ),

                  const SizedBox(height: gap + 4),

                  // Message d'erreur
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Bouton créer compte
                  SizedBox(
                    width: fieldWidth,
                    height: fieldHeight,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF357E50),
                        disabledBackgroundColor: const Color(0xFF357E50).withAlpha(120),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(arrondi)),
                        padding: EdgeInsets.zero,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Créer mon compte',
                              style: TextStyle(fontSize: 14, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
