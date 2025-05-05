import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/category_controller.dart';

class KategoriPage extends StatelessWidget {
  final KategoriController controller = Get.put(KategoriController());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();  // Menambahkan GlobalKey untuk Form

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Category', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,  // Menambahkan key untuk form
          child: Column(
            children: [
              // Field untuk nama kategori
              TextFormField(
                controller: controller.namaKategoriController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama kategori wajib diisi';
                  }
                  return null;
                },
                onChanged: (value) => controller.namaKategori.value = value,
                decoration: InputDecoration(
                  labelText: 'Nama Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Dropdown untuk status kategori
              DropdownButtonFormField<int>(
                value: controller.statusKategori.value,
                decoration: InputDecoration(
                  labelText: 'Tipe Kategori',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Penerimaan')),
                  DropdownMenuItem(value: 1, child: Text('Pengeluaran')),
                ],
                onChanged: (value) {
                  if (value != null) controller.statusKategori.value = value;
                },
                validator: (value) {
                  if (value == null) {
                    return 'Pilih tipe kategori';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Tombol untuk menyimpan kategori
              Obx(() => controller.isLoading.value
                  ? CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          controller.submitKategori();
                        }
                      },
                      icon: Icon(Icons.save, color: Colors.white),
                      label: Text(
                        'Simpan',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
