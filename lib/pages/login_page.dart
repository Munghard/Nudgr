import 'package:flutter/material.dart';
import 'package:nudgr/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final supabase = Supabase.instance.client;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        Provider.google,
        redirectTo: null,
        // redirectTo: 'http://localhost:3000/',
        // redirectTo: 'io.supabase.flutter://login-callback',
        // redirectTo: 'https://vjzxvusrqlvtqbltutsu.supabase.co/auth/v1/callback',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    }
  }

  Future<void> signIn() async {
  setState(() => loading = true);
  try {
    final response = await supabase.auth.signInWithPassword(
      email: emailController.text,
      password: passwordController.text,
    );

    final session = response.session;
    if (session != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed')),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login error: $error')),
    );
  }
  setState(() => loading = false);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              onPressed: () => _signInWithGoogle(context),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: signIn,
                    child: const Text('Sign In'),
                  ),
          ],
        ),
      ),
    );
  }
}
