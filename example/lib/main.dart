import 'package:flutter/material.dart';

void main() => runApp(const SignUpApp());

/// Keys for the widgets that the example's layout tests look at.
abstract final class SignUpKeys {
  static const Key title = Key('title');
  static const Key subtitle = Key('subtitle');
  static const Key name = Key('name');
  static const Key email = Key('email');
  static const Key password = Key('password');
  static const Key confirm = Key('confirm');
  static const Key terms = Key('terms');
  static const Key submit = Key('submit');
}

/// A small app with one sign-up screen.
class SignUpApp extends StatelessWidget {
  const SignUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'layout_matchers example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const SignUpScreen(),
    );
  }
}

/// A sign-up form whose layout is checked by the example's tests.
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(
            'Join in a minute',
            key: SignUpKeys.title,
            style: text.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'We only need four things.',
            key: SignUpKeys.subtitle,
            style: text.bodyMedium,
          ),
          const SizedBox(height: 24),
          const _Field(key: SignUpKeys.name, label: 'Name'),
          const SizedBox(height: 16),
          const _Field(key: SignUpKeys.email, label: 'Email'),
          const SizedBox(height: 16),
          const _Field(key: SignUpKeys.password, label: 'Password'),
          const SizedBox(height: 16),
          const _Field(key: SignUpKeys.confirm, label: 'Confirm password'),
          const SizedBox(height: 24),
          Text(
            'By creating an account you agree to the terms of use.',
            key: SignUpKeys.terms,
            style: text.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: SignUpKeys.submit,
            onPressed: () {},
            child: const Text('Create account'),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
