import 'package:flutter/material.dart';
import 'package:nudgr/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  
  
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final supabase = Supabase.instance.client;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  Future<void> signUp() async {
  setState(() => loading = true);
  try {
    final res = await supabase.auth.signUp(
      email: emailController.text,
      password: passwordController.text,
    );

    final session = res.session;
    if (session != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => 
           HomePage(),
          )
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Register failed')),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Register error: $error')),
    );
  }
  setState(() => loading = false);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                    onPressed: signUp,
                    child: const Text('Sign up'),
                  ),
          ],
        ),
      ),
    );
  }
}
