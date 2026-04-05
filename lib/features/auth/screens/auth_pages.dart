import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../home/screens/main_screen.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

// ====================================================================
// PAGE 5: CONNEXION
// ====================================================================

class LoginPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const LoginPage({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final ApiService _api = ApiService();
  final TextEditingController _emailController = TextEditingController();
  int? userId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: widget.themeMode,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        primaryColor: const Color(0xFF00897B),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF00897B),
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF00897B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: Stack(
                      children: [
                        _buildStackBox(0, 0, 180, 150, const Color(0xFFB3E5FC),
                            Icons.smartphone, const Color(0xFF0277BD),
                            size: 50),
                        _buildStackBox(
                            0, 200, 0, 80, const Color(0xFFE1BEE7), null, null),
                        _buildStackBox(
                            100,
                            0,
                            200,
                            200,
                            const Color(0xFFFFF9C4),
                            Icons.weekend,
                            const Color(0xFFF57F17),
                            size: 80),
                        _buildStackBox(90, 200, 0, 140, const Color(0xFFFFCCBC),
                            Icons.toys, const Color(0xFFE64A19),
                            size: 60),
                        _buildStackBox(
                            null,
                            0,
                            200,
                            120,
                            const Color(0xFFF8BBD0),
                            Icons.directions_car,
                            const Color(0xFFC2185B),
                            size: 60,
                            bottom: 0),
                        _buildStackBox(
                            null,
                            200,
                            0,
                            100,
                            const Color(0xFFB2DFDB),
                            Icons.work_outline,
                            const Color(0xFF00695C),
                            size: 50,
                            bottom: 0),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Connectez-vous ou créez\nvotre compte marketmboa',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _emailController,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'E-mail *',
                      labelStyle: TextStyle(color: Theme.of(context).hintColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: () async {
                      final email = _emailController.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Veuillez entrer votre email'),
                              backgroundColor: Colors.red),
                        );
                        return;
                      }

                      // Validation du format de l'email
                      final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(email)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Veuillez entrer un email valide'),
                              backgroundColor: Colors.red),
                        );
                        return;
                      }

                      try {
                        final result = await _api.register(email);
                        if (result['userId'] == null) {
                          throw Exception('Erreur serveur: userId manquant');
                        }
                        setState(() => userId = result['userId']);
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EmailVerification(
                              userId: userId!,
                              email: email,
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Erreur: ${e.toString()}'),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFAB91),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Continuer',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                      child: Text('Ou',
                          style: TextStyle(color: Colors.grey, fontSize: 16))),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStackBox(double? top, double? left, double? right, double height,
      Color color, IconData? icon, Color? iconColor,
      {double? size, double? bottom}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        height: height,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(20)),
        child: icon != null
            ? Center(child: Icon(icon, size: size, color: iconColor))
            : null,
      ),
    );
  }
}

class EmailVerification extends StatefulWidget {
  final int userId;
  final String email;
  const EmailVerification(
      {super.key, required this.userId, required this.email});
  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  final ApiService _api = ApiService();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Code envoyé à ${widget.email}'),
              backgroundColor: const Color(0xFF00897B)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
                value: 0.2,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35))),
            const SizedBox(height: 30),
            Text('Entrez votre mot de passe',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 10),
            Text('Saisissez votre mot de passe pour continuer.',
                style:
                    TextStyle(color: Theme.of(context).hintColor, height: 1.5)),
            const SizedBox(height: 40),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFAB91),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Continuer',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyCode() async {
    final pwd = _passwordController.text.trim();
    if (pwd.isEmpty) {
      return;
    }
    try {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: widget.email.trim(), password: pwd);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          final cred = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                  email: widget.email.trim(), password: pwd);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .set({
            'email': widget.email.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          rethrow;
        }
      }

      if (context.mounted) {
        final loginRes = await _api.login(widget.email.trim());
        if (loginRes['success'] == false) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(loginRes['message'] ?? 'Erreur de connexion'),
              backgroundColor: Colors.red,
            ));
          }
          await FirebaseAuth.instance.signOut();
          return;
        }
        if (loginRes['isComplete'] == true) {
          AuthService.setLoggedIn(loginRes['username']);
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => MainScreen(
                        toggleTheme: () {}, themeMode: ThemeMode.light)),
                (route) => false);
          }
        } else {
          if (context.mounted) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        PhoneNumberEntry(userId: widget.userId)));
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

class PhoneNumberEntry extends StatefulWidget {
  final int userId;
  const PhoneNumberEntry({super.key, required this.userId});
  @override
  State<PhoneNumberEntry> createState() => _PhoneNumberEntryState();
}

class _PhoneNumberEntryState extends State<PhoneNumberEntry> {
  final ApiService _api = ApiService();
  final _phoneController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Numéro de téléphone')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Téléphone', prefixText: '+237 ')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final phone = _phoneController.text.trim();
                if (phone.length != 9) return;
                await _api.addPhone(widget.userId, '+237$phone');
                if (!mounted) return;
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SignUpStep1(userId: widget.userId)));
              },
              child: const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpStep1 extends StatefulWidget {
  final int userId;
  const SignUpStep1({super.key, required this.userId});
  @override
  State<SignUpStep1> createState() => _SignUpStep1State();
}

class _SignUpStep1State extends State<SignUpStep1> {
  final ApiService _api = ApiService();
  String _accountType = 'personal';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Type de compte')),
      body: Column(
        children: [
          RadioListTile(
              value: 'personal',
              groupValue: _accountType,
              onChanged: (v) => setState(() => _accountType = v!),
              title: const Text('Personnel')),
          RadioListTile(
              value: 'business',
              groupValue: _accountType,
              onChanged: (v) => setState(() => _accountType = v!),
              title: const Text('Entreprise')),
          ElevatedButton(
            onPressed: () async {
              await _api.updateAccountType(widget.userId, _accountType);
              if (!mounted) return;
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SignUpStep2(userId: widget.userId)));
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }
}

class SignUpStep2 extends StatefulWidget {
  final int userId;
  const SignUpStep2({super.key, required this.userId});
  @override
  State<SignUpStep2> createState() => _SignUpStep2State();
}

class _SignUpStep2State extends State<SignUpStep2> {
  final ApiService _api = ApiService();
  final _usernameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nom d\'utilisateur')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Pseudo')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_usernameController.text.isEmpty) return;
                await _api.completeRegistration(
                    userId: widget.userId, username: _usernameController.text);
                if (!mounted) return;
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SignUpSuccess(username: _usernameController.text)));
              },
              child: const Text('Terminer'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpSuccess extends StatelessWidget {
  final String username;
  const SignUpSuccess({super.key, required this.username});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            Text('Bienvenue $username !'),
            ElevatedButton(
              onPressed: () async {
                AuthService.setLoggedIn(username);
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => MainScreen(
                              toggleTheme: () {}, themeMode: ThemeMode.light)),
                      (route) => false);
                }
              },
              child: const Text('C\'est parti'),
            ),
          ],
        ),
      ),
    );
  }
}
