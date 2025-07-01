import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart'; // Adjust path if needed

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _domainNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final fullName = _fullNameController.text.trim();
      final companyName = _companyNameController.text.trim();
      final domainName = _domainNameController.text.trim();
      final address = _addressController.text.trim();
      final mobile = _mobileController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final url = Uri.parse(
          "https://darktechteam.com/dtt_accounts/public/api/tregister",
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'full_name': fullName,
            'company_name': companyName,
            'domain': domainName,
            'address': address,
            'mobile_number': mobile,
            'email': email,
            'password': password,
          }),
        );

        Navigator.pop(context); // Close loading dialog

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          final user = data['data']['user'];
          final token = data['data']['token'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setString('user_name', user['name']);
          await prefs.setString('email', user['email']);
          await prefs.setInt('user_id', user['id']);

          final message = data['message']?.toString().toLowerCase() ?? "";

          // Show success alert and redirect to LoginPage
          if (message.contains("registration") || message.contains("login")) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("✅ Success"),
                content: Text("${data['message']}\nRedirecting to login..."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ ${data['message'] ?? 'Registration failed'}"),
            ),
          );
        }
      } catch (e) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Error: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text("Register"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.app_registration,
                    size: 64,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Create an Account",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),

                  _buildTextField(
                    _fullNameController,
                    Icons.person,
                    'Full Name',
                    'Please enter Full Name',
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    _companyNameController,
                    Icons.business,
                    'Company Name',
                    'Please enter Company Name',
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    _domainNameController,
                    Icons.language,
                    'Domain Name',
                    'Please enter Domain Name',
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    _addressController,
                    Icons.location_on,
                    'Address',
                    'Please enter Address',
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('Mobile', Icons.phone),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter Mobile';
                      if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value))
                        return 'Enter valid Mobile number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Email', Icons.email),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter Email';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                        return 'Enter a valid Email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _inputDecoration('Password', Icons.lock),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter Password' : null,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: _inputDecoration(
                      'Confirm Password',
                      Icons.lock_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please confirm password';
                      if (value != _passwordController.text)
                        return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.app_registration,
                        color: Colors.white,
                      ),
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: const Text(
                        'REGISTER',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    IconData icon,
    String label,
    String validator,
  ) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      validator: (value) => value!.isEmpty ? validator : null,
    );
  }
}
