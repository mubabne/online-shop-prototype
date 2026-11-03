import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';

/// Прототипын нэвтрэх дэлгэц: дүрээ сонгоод жишээ хэрэглэгчээр нэвтэрнэ.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const _roles = [
    (UserRole.guest, Icons.person_outline_rounded,
        'Бүртгэлгүйгээр бараа, дэлгүүр хайж үзэх'),
    (UserRole.buyer, Icons.shopping_bag_outlined,
        'Захиалга өгөх, хянах, үнэлгээ өгөх'),
    (UserRole.merchant, Icons.storefront_outlined,
        'Дэлгүүр, бараа, захиалга, борлуулалт'),
    (UserRole.courier, Icons.delivery_dining_outlined,
        'Хүргэлт хүлээн авах, хуваарилах'),
    (UserRole.admin, Icons.admin_panel_settings_outlined,
        'Тайлан, бүтээгдэхүүн, дэлгүүр, гомдол'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Градиент дэвсгэр + чимэглэлийн тойргууд
          Container(
            height: 330,
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
          ),
          const Positioned(top: -40, right: -30, child: _Bubble(160)),
          const Positioned(top: 140, left: -50, child: _Bubble(120)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                FadeSlideIn(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_bag_rounded,
                            size: 52, color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      const Text('Онлайн дэлгүүр',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('Нэг дороос бүх дэлгүүр',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                for (var i = 0; i < _roles.length; i++)
                  FadeSlideIn(
                    index: i + 1,
                    child: _RoleCard(
                      role: _roles[i].$1,
                      icon: _roles[i].$2,
                      subtitle: _roles[i].$3,
                      onTap: () => _roles[i].$1 == UserRole.guest
                          ? app.continueAsGuest()
                          : _pickUser(context, _roles[i].$1),
                    ),
                  ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  index: 7,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    icon: const Icon(Icons.person_add_alt_rounded),
                    label: const Text('Шинээр бүртгэл үүсгэх'),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final colors = AppColors.role(role);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${role.label} — данс сонгох',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (var i = 0; i < candidates.length; i++)
              FadeSlideIn(
                index: i,
                child: ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      shape: BoxShape.circle,
                    ),
                    child: Text(candidates[i].name.characters.first,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(candidates[i].name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(candidates[i].phone),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    app.loginAs(candidates[i]);
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.size);

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
        ),
      );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.icon,
    required this.subtitle,
    required this.onTap,
  });

  final UserRole role;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.role(role);
    return Pressable(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 6,
        shadowColor: colors.first.withValues(alpha: 0.25),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: colors.first),
            ],
          ),
        ),
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
    toast(context, 'Бүртгэл амжилттай үүслээ');
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? 'Заавал бөглөнө' : null;
    final fields = [
      TextFormField(
        controller: _name,
        decoration: const InputDecoration(
            labelText: 'Нэр', prefixIcon: Icon(Icons.person_outline)),
        validator: required,
      ),
      TextFormField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
            labelText: 'Утасны дугаар', prefixIcon: Icon(Icons.phone_outlined)),
        validator: (v) => (v == null || v.trim().length < 8)
            ? '8 оронтой дугаар оруулна уу'
            : null,
      ),
      TextFormField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
            labelText: 'И-мэйл (заавал биш)',
            prefixIcon: Icon(Icons.alternate_email)),
      ),
      TextFormField(
        controller: _address,
        decoration: const InputDecoration(
            labelText: 'Хүргэлтийн хаяг',
            prefixIcon: Icon(Icons.location_on_outlined)),
        validator: required,
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Бүртгэл үүсгэх')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const FadeSlideIn(
              child: Text(
                'Бүртгүүлээд сагс, захиалга, үнэлгээ, чат зэрэг бүх боломжийг ашиглаарай.',
              ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < fields.length; i++)
              FadeSlideIn(
                index: i + 1,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: fields[i],
                ),
              ),
            const SizedBox(height: 8),
            FadeSlideIn(
              index: 6,
              child: FilledButton(
                  onPressed: _submit, child: const Text('Бүртгүүлэх')),
            ),
          ],
        ),
      ),
    );
  }
}
