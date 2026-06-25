import 'package:cal_track_v1/Pages/donnees_utilisateur.dart';
import 'package:cal_track_v1/Pages/politique_confidentialite_page.dart';
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
final prenomController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedPrivacy = false;

  static const double fieldHeight = 40;
  static const double gap = 15;
  static const double arrondi = 10;

  bool get _canSubmit =>
      prenomController.text.trim().isNotEmpty &&
emailController.text.trim().isNotEmpty &&
      passwordController.text.length >= 6 &&
      _acceptedPrivacy;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
prenomController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedPrivacy) {
      setState(() => _errorMessage = "Veuillez accepter la politique de confidentialité.");
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await userCredential.user!.updateDisplayName(prenomController.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': emailController.text.trim(),
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
    final double fieldWidth = MediaQuery.of(context).size.width * 0.85;
    return Scaffold(
      backgroundColor: const Color(0xFF393939),
      appBar: AppBar(
        backgroundColor: const Color(0xFF393939),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 120),
          Center(
            child: Container(
              width: 18,
              height: 63,
              decoration: BoxDecoration(
                color: const Color(0x32D9D9D9),
                borderRadius: BorderRadius.circular(36),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(-2, 2)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                Form(
                key: _formKey,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                  const Text(
                    'Nouveau profil',
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
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDecoration('Prénom', Icons.person_outline),
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
                      onChanged: (_) => setState(() {}),
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
                      onChanged: (_) => setState(() {}),
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

                  // Politique de confidentialité
                  SizedBox(
                    width: fieldWidth,
                    child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _acceptedPrivacy,
                          onChanged: (v) => setState(() {
                            _acceptedPrivacy = v ?? false;
                            if (_acceptedPrivacy) _errorMessage = null;
                          }),
                          activeColor: const Color(0xFF357E50),
                          side: const BorderSide(color: Colors.white38),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                            children: [
                              const TextSpan(text: "J'accepte la "),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PolitiqueConfidentialitePage(),
                                    ),
                                  ),
                                  child: const Text(
                                    'politique de confidentialité',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 93, 211, 136),
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF357E50),
                                    ),
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

                  const SizedBox(height: 20),

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
                      onPressed: (_canSubmit && !_isLoading) ? _register : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF357E50),
                        disabledBackgroundColor: const Color(0xFF6E6E6E),
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
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 18,
                    height: 63,
                    decoration: BoxDecoration(
                      color: const Color(0x32D9D9D9),
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(-2, 2)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
