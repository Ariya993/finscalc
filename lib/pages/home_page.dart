import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/category_controller.dart';
import '../controllers/home_controller.dart';

class HomePage extends GetView<HomeController> {
  HomePage({Key? key}) : super(key: key);
  final categorycontroller = Get.put(KategoriController());

  final List<String> bulanList = [
    'Semua',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (categorycontroller.categories.isEmpty) {
        categorycontroller.fetchCategories();
      }
      controller.fetchDashboardData();
    });
    return RefreshIndicator(
      onRefresh: () => controller.fetchDashboardData(),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            SizedBox(height: 24),
            _buildFilterBulan(),
            SizedBox(height: 16),
            Text(
              'Transaksi Terakhir',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 16),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBulan() {
    return Obx(() => DropdownButtonFormField<int>(
          value: controller.selectedMonth.value,
          decoration: InputDecoration(
            labelText: 'Filter Bulan',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: List.generate(bulanList.length, (index) {
            return DropdownMenuItem(
              value: index,
              child: Text(bulanList[index]),
            );
          }),
          onChanged: (value) {
            if (value != null) controller.selectedMonth.value = value;
          },
        ));
  }

  Widget _buildSummaryCards() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.selectedJenis.value = 0,
                  child: _buildCard(
                    'Penerimaan',
                    controller.formatCurrency(controller.totalPenerimaan.value),
                    Colors.green.shade100,
                    Icons.download_rounded,
                    Colors.green,
                    isSelected: controller.selectedJenis.value == 0,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.selectedJenis.value = 1,
                  child: _buildCard(
                    'Pengeluaran',
                    controller.formatCurrency(controller.totalPengeluaran.value),
                    Colors.red.shade100,
                    Icons.upload_rounded,
                    Colors.red,
                    isSelected: controller.selectedJenis.value == 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: () => controller.selectedJenis.value = -1,
            child: _buildCard(
              'Saldo',
              controller.formatCurrency(controller.saldo.value),
              Colors.blue.shade100,
              Icons.account_balance_wallet,
              Colors.blue,
              fullWidth: true,
              isSelected: controller.selectedJenis.value == -1,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCard(
    String title,
    String amount,
    Color bgColor,
    IconData icon,
    Color iconColor, {
    bool fullWidth = false,
    bool isSelected = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: iconColor, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            fullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: fullWidth
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
              Icon(icon, color: iconColor),
            ],
          ),
          SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: fullWidth ? 28 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      final transaksiList = controller.filteredTransaksi;

      if (transaksiList.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Belum ada transaksi',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: transaksiList.length,
        itemBuilder: (context, index) {
          final transaksi = transaksiList[index];
          final isIncome = transaksi['status'] == 0;
          final nominal = double.tryParse(transaksi['nominal'].toString()) ?? 0;

          return Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    isIncome ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(
                  isIncome ? Icons.download_rounded : Icons.upload_rounded,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              title: Text(transaksi['description'] ?? 'Tidak ada deskripsi'),
              subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(controller.formatTanggal(transaksi['tanggal'])),
                Text(
                  categorycontroller.categories
                          .firstWhereOrNull((c) => c.id == transaksi['id_category'])
                          ?.category ??
                      'Kategori tidak ditemukan',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
              trailing: Text(
                controller.formatCurrency(nominal),
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
