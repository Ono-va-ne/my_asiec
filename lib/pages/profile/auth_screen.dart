import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../messenger/chat_list_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLoginMode = true; // true = Вход, false = Регистрация
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _groupController = TextEditingController();

  String selectedRole = 'student'; // Значение по умолчанию

  final Map<String, String> rolesMap = {
    'student': 'Студент',
    'teacher': 'Преподаватель',
    'council': 'Студенческий совет',
    'director': 'Дирекция',
    'admin': 'Администратор',
  };

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (isLoginMode) {
        // Вход
        await AuthService.login(
          _loginController.text.trim(),
          _passwordController.text.trim(),
        );

        if (mounted) {
          // Просто возвращаемся на предыдущий экран (MoreScreen или ChatListScreen)
          Navigator.pop(context, true); 
        }
      } else {
        // Регистрация
        await AuthService.register(
          login: _loginController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _fullNameController.text.trim(),
          role: selectedRole,
          studentGroup: selectedRole == 'student' ? _groupController.text.trim() : null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Успешная регистрация! Теперь войдите.')),
        );

        setState(() {
          isLoginMode = true; // Переключаем на вход после успешной регистрации
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLoginMode ? 'Вход в систему' : 'Регистрация'),

      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  "МойАПЭК",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),

                // Логин
                TextFormField(
                  controller: _loginController,
                  decoration: const InputDecoration(
                    labelText: 'Логин',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Введите логин' : null,
                ),
                const SizedBox(height: 12),

                // Пароль
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Введите пароль' : null,
                ),
                const SizedBox(height: 12),

                // Доп. поля для Регистрации
                if (!isLoginMode) ...[
                  // ФИО
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Фамилия Имя',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Введите Имя и Фамилию' : null,
                  ),
                  const SizedBox(height: 12),

                  // Выбор Роли
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Тип профиля',
                      prefixIcon: Icon(Icons.work),
                      border: OutlineInputBorder(),
                    ),
                    items: rolesMap.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => selectedRole = val!),
                  ),
                  const SizedBox(height: 12),

                  // Группа (показываем только для студентов)
                  if (selectedRole == 'student') ...[
                    TextFormField(
                      controller: _groupController,
                      decoration: const InputDecoration(
                        labelText: 'Группа (например: ИС-21)',
                        prefixIcon: Icon(Icons.group),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => selectedRole == 'student' && v!.isEmpty
                          ? 'Укажите учебную группу'
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],

                const SizedBox(height: 12),

                // Кнопка Отправки
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isLoginMode ? 'Войти' : 'Зарегистрироваться'),
                  ),
                ),

                // Переключатель Режим Входа / Регистрации
                TextButton(
                  onPressed: () {
                    setState(() => isLoginMode = !isLoginMode);
                  },
                  child: Text(
                    isLoginMode
                        ? 'Нет аккаунта? Зарегистрироваться'
                        : 'Уже есть аккаунт? Войти',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}