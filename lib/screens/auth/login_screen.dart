import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget{
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_userCtrl.text.trim(), _passCtrl.text);
    if (success && mounted) context.go('/inventory');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [

            const SizedBox(height: 48),
            Text('Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
            
            const SizedBox(height: 8),
            Text('Log in to your household',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            
            //email
            const SizedBox(height: 40),
            TextField(
              controller: _userCtrl,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),

            //password
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              ),
            ),

            //Error Message
            const SizedBox(height: 12),
            if (auth.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(auth.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),

            //Login Button
            SizedBox(
              width:  double.infinity,
              child: FilledButton(
                onPressed: auth.isLoading ? null : _submit, 
                child: auth.isLoading
                      ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Log in'),
              ),
            ),

            //Go to Register
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.go('/register'),
                child: const Text("Don't have an account? Register"),
              )
            )
           ], 
          )
        )
      )
    );
  }
}