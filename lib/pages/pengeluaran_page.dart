import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/category_controller.dart';
import '../controllers/pengeluaran_controller.dart';
import '../helper/endpoint.dart';
import 'pengeluaran_form.dart';

class PengeluaranPage extends StatelessWidget {
  final controller = Get.put(PengeluaranController());
  final categorycontroller = Get.put(KategoriController());

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (categorycontroller.categories.isEmpty) {
        categorycontroller.fetchCategories();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text('Pengeluaran')),
      body: Obx(() {
        final filteredCategories = categorycontroller.categories
            .where((c) => c.status == 1)
            .toList();

        final dropdownItems = [
          DropdownMenuItem<int>(
            value: 0,
            child: Text('Semua'),
          ),
          ...filteredCategories.map((c) => DropdownMenuItem<int>(
                value: c.id,
                child: Text(c.category),
              ))
        ];

        final data = controller.filteredPengeluaran;

        return Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: controller.filterKategori.value,
                decoration: InputDecoration(
                  labelText: 'Filter Kategori',
                  labelStyle: TextStyle(color: Colors.black),
                ),
                items: dropdownItems,
                onChanged: (val) {
                  if (val != null) controller.filterKategori.value = val;
                },
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          controller.filterTanggalMulai.value = picked;
                        }
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(controller.filterTanggalMulai.value != null
                            ? DateFormat('dd MMM yyyy').format(
                                controller.filterTanggalMulai.value!)
                            : 'Mulai'),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          controller.filterTanggalSelesai.value = picked;
                        }
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(controller.filterTanggalSelesai.value != null
                            ? DateFormat('dd MMM yyyy').format(
                                controller.filterTanggalSelesai.value!)
                            : 'Selesai'),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.filterKategori.value = 0;
                      controller.filterTanggalMulai.value = null;
                      controller.filterTanggalSelesai.value = null;
                    },
                    icon: Icon(Icons.clear),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Expanded(
                child: controller.pengeluaranList.isEmpty
                    ? Center(child: Text('Belum ada data'))
                    : ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final item = data[index];
                          final nominal = NumberFormat.currency(
                                  locale: 'id',
                                  symbol: 'Rp ',
                                  decimalDigits: 0)
                              .format(item['nominal']);
                          final tanggal = DateFormat('dd MMM yyyy')
                              .format(DateTime.parse(item['tanggal']));
                          final imageUrl = '$host${item['imageFile']}';

                                  return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          margin: EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Icon(Icons.image_not_supported),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['description'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        nominal,
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(tanggal),
                  Text(
                    categorycontroller.categories
                            .firstWhereOrNull((cat) => cat.id == item['id_category'])
                            ?.category ??
                        'Kategori tidak ditemukan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                Get.to(() => PengeluaranForm(), arguments: item);
              },
              icon: Icon(Icons.edit, color: Colors.blue),
              label: Text("Edit", style: TextStyle(color: Colors.blue)),
            ),
            SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                Get.defaultDialog(
                  title: 'Konfirmasi',
                  middleText: 'Yakin ingin menghapus data ini?',
                  textConfirm: 'Ya',
                  textCancel: 'Batal',
                  confirmTextColor: Colors.white,
                  onConfirm: () async {
                    await controller.deletePengeluaran(item['id']);
                    Get.back();
                  },
                );
              },
              icon: Icon(Icons.delete, color: Colors.red),
              label: Text("Hapus", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ],
    ),
  ),
);
                        },
                      ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => PengeluaranForm());
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
