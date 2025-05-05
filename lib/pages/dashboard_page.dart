import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../controllers/home_controller.dart';
import '../controllers/login_controller.dart';
import '../controllers/penerimaan_controller.dart';
import '../controllers/pengeluaran_controller.dart';
import 'penerimaan_page.dart';
import 'pengeluaran_page.dart';
import 'home_page.dart';

class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final LoginController controller = Get.put(LoginController());
  int _selectedIndex = 1;
  final username = GetStorage().read('username') ?? 'Pengguna';
 final List<Widget Function()> _pages = [
    () => PenerimaanPage(),
    () => HomePage(),
    () => PengeluaranPage(),
  ];


  @override
  void initState() {
    super.initState();

    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }
    if (!Get.isRegistered<PenerimaanController>()) {
      Get.put(PenerimaanController());
    }
    if (!Get.isRegistered<PengeluaranController>()) {
      Get.put(PengeluaranController());
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      Get.find<PenerimaanController>().fetchPenerimaan();
    } else if (index == 1) {
      Get.find<HomeController>().fetchDashboardData();
    } else if (index == 2) {
      Get.find<PengeluaranController>().fetchPengeluaran();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade600,
        title: const Text("Fins Tracking",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => controller.logout(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 64,
                    width: 64,
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    username,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Master Kategori'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed('/kategori-form');
              },
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex](),
      ),
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.download_rounded),
            selectedIcon: Icon(Icons.download_rounded, color: Colors.blue),
            label: 'Penerimaan',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.blue),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_rounded),
            selectedIcon: Icon(Icons.upload_rounded, color: Colors.blue),
            label: 'Pengeluaran',
          ),
        ],
        elevation: 3,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: Colors.blue.shade100,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
