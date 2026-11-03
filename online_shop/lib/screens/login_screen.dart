import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';

/// Прототипын нэвтрэх дэлгэц: дүрээ сонгоод жишээ хэрэглэгчээр нэвтэрнэ.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 24),
            Icon(Icons.storefront, size: 72, color: scheme.primary),
            const SizedBox(height: 12),
            Text('Онлайн дэлгүүр',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Дүрээ сонгож нэвтэрнэ үү',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            _RoleCard(
              icon: Icons.person_outline,
              title: UserRole.guest.label,
              subtitle: 'Бүртгэлгүйгээр бараа, дэлгүүр хайж үзэх',
              onTap: app.continueAsGuest,
            ),
            _RoleCard(
              icon: Icons.shopping_cart_outlined,
              title: UserRole.buyer.label,
              subtitle: 'Захиалга өгөх, хянах, үнэлгээ өгөх',
              onTap: () => _pickUser(context, UserRole.buyer),
            ),
            _RoleCard(
              icon: Icons.store_outlined,
              title: UserRole.merchant.label,
              subtitle: 'Дэлгүүр, бараа, захиалга, борлуулалт удирдах',
              onTap: () => _pickUser(context, UserRole.merchant),
            ),
            _RoleCard(
              icon: Icons.local_shipping_outlined,
              title: UserRole.courier.label,
              subtitle: 'Хүргэлт хүлээн авах, хуваарилах, баталгаажуулах',
              onTap: () => _pickUser(context, UserRole.courier),
            ),
            _RoleCard(
              icon: Icons.admin_panel_settings_outlined,
              title: UserRole.admin.label,
              subtitle: 'Тайлан, бүтээгдэхүүн, дэлгүүр, гомдол хянах',
              onTap: () => _pickUser(context, UserRole.admin),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const RegisterScreen())),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Шинээр бүртгэл үүсгэх'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickUser(BuildContext context, UserRole role) {
    final app = AppScope.read(context);
    final candidates = app.usersByRole(role);
    if (candidates.length == 1) {
      app.loginAs(candidates.first);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${role.label} — данс сонгох',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final u in candidates)
              ListTile(
                leading: CircleAvatar(child: Text(u.name.characters.first)),
                title: Text(u.name),
                subtitle: Text(u.phone),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  app.loginAs(u);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Use case: Бүртгэл үүсгэх (Зочин → Худалдан авагч)
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    AppScope.read(context).register(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
    );
    Navigator.of(context).popUntil((r) => r.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Бүртгэл амжилттай үүслээ')));
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? 'Заавал бөглөнө' : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Бүртгэл үүсгэх')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Нэр', border: OutlineInputBorder()),
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Утасны дугаар', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().length < 8)
                  ? '8 оронтой дугаар оруулна уу'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'И-мэйл (заавал биш)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                  labelText: 'Хүргэлтийн хаяг', border: OutlineInputBorder()),
              validator: required,
            ),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: _submit, child: const Text('Бүртгүүлэх')),
          ],
        ),
      ),
    );
  }
}
