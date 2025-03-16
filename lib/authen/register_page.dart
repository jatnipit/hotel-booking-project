import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  Future<void> resetUserState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('discountPercentage', 0.0);
    await prefs
        .remove('discount_used_${FirebaseAuth.instance.currentUser?.uid}');
  }

  Future<void> signUserUp() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (passwordController.text != confirmPasswordController.text) {
        if (mounted) {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Passwords do not match!'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK')),
              ],
            ),
          );
        }
        return;
      }

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = FirebaseAuth.instance.currentUser!.uid;
      String name =
          '${firstNameController.text.trim()} ${lastNameController.text.trim()}';

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': emailController.text.trim(),
      });

      await resetUserState();

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const MyApp()));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(e.message ?? 'An unknown error occurred'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK')),
            ],
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save user data: ${e.message}'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: const Center(child: Text('Example Firebase')),
        actions: const [Icon(Icons.help)],
        backgroundColor: Theme.of(context).primaryColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        margin: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Center(
                child: Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: firstNameController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'First Name',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter your first name'
                              : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: lastNameController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Last Name',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter your last name'
                              : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: emailController,
                      autofocus: true,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Email',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter email'
                          : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Password',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter password'
                          : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Confirm Password',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter confirm password'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: signUserUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
