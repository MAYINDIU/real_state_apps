import 'package:flutter/material.dart';
import 'package:realestate/Screens/AllUsersPage.dart';
import 'package:realestate/screens/clients.dart';
import 'package:realestate/screens/collection_entry.dart';
import 'package:realestate/screens/collection_statement_page.dart';
import 'package:realestate/screens/expenseentry.dart';
import 'package:realestate/screens/flat_sale.dart';
import 'package:realestate/screens/flatplot.dart';
import 'package:realestate/screens/login.dart';
import 'package:realestate/screens/projects.dart';
import 'package:realestate/screens/referenceinfo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String username = 'User';
  String role = 'Role';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'User';
      role = prefs.getString('role') ?? 'Role';
    });
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  Widget _buildCard(String title, String imagePath, VoidCallback onTap) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(imagePath, height: 40, width: 40),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0097A7);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 6,
        title: const Text(
          "DASHBOARD",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/real_estate.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.bottomLeft,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Text(
                'Welcome, $username',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 6,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
                children: [
                  _buildCard("Project", "assets/icons/project.png", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProjectInfoPage(),
                      ),
                    );
                  }),
                  _buildCard(
                    "Client Information",
                    "assets/icons/clientinfo.png",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ClientsPage()),
                      );
                    },
                  ),
                  _buildCard(
                    "Reference Information",
                    "assets/icons/reference.png",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReferenceInfoPage(),
                        ),
                      );
                    },
                  ),
                  _buildCard("Flat Sale", "assets/icons/flatsale.png", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FlatSalePage()),
                    );
                  }),
                  _buildCard("Flat -Plot", "assets/icons/flot.png", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FlatPlotPage()),
                    );
                  }),
                  _buildCard("Collection", "assets/icons/collection.png", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CollectionEntryPage(),
                      ),
                    );
                  }),

                  _buildCard(
                    "Collection Statement",
                    "assets/icons/statement.png",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CollectionStatementPage(),
                        ),
                      );
                    },
                  ),
                  _buildCard("User Management", "assets/icons/user.png", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllUsersPage()),
                    );
                  }),
                  _buildCard("Expense Entry", "assets/icons/expense.png", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExpenseEntryPage(),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
