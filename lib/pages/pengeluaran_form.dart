 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/category_controller.dart';
import '../controllers/pengeluaran_controller.dart';
import '../helper/endpoint.dart';

class PengeluaranForm extends StatefulWidget {
  @override
  State<PengeluaranForm> createState() => _PengeluaranFormState();
}

class _PengeluaranFormState extends State<PengeluaranForm> {
  final controller = Get.find<PengeluaranController>();
  final categoryController = Get.find<KategoriController>();
  Map<String, dynamic>? editData;

  @override
  void initState() {
    super.initState();

    editData = Get.arguments;

    if (editData != null) {
      controller.nominalController.text = editData!['nominal'].toString();
      controller.deskripsiController.text = editData!['description'];
      controller.selectedDate.value = DateTime.parse(editData!['tanggal']);
      controller.selectedCategory.value = editData!['id_category'];
    } else {
      controller.clearForm();
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller.clearForm();
  }

  void _submit() async {
    if (editData != null) {
      await controller.updatePengeluaran(editData!['id']);
    } else {
      await controller.submitPengeluaran();
    }

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
  editData != null ? 'Edit Pengeluaran' : 'Form Pengeluaran',
  style: TextStyle(color: Colors.white),
),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Obx(() {
          final filteredCategories = categoryController.categories
              .where((c) => c.status ==  1) // status 1 = Pengeluaran
              .toList();

          final dropdownItems = filteredCategories
              .map((c) => DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(c.category),
                  ))
              .toList();

          final currentValue = filteredCategories
                  .any((c) => c.id == controller.selectedCategory.value)
              ? controller.selectedCategory.value
              : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tanggal picker
              GestureDetector(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: controller.selectedDate.value,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    controller.selectedDate.value = picked;
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Tanggal',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: DateFormat('yyyy-MM-dd')
                          .format(controller.selectedDate.value),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Nominal
              TextFormField(
                controller: controller.nominalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nominal',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 16),

              // Deskripsi
              TextFormField(
                controller: controller.deskripsiController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              SizedBox(height: 16),

              // Kategori
              DropdownButtonFormField<int>(
                value: currentValue,
                items: dropdownItems,
                onChanged: (value) {
                  if (value != null) {
                    controller.selectedCategory.value = value;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // Upload gambar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  controller.imageFile.value != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            controller.imageFile.value!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : editData != null && editData!['imageFile'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network( 
                                '$host${editData!['imageFile']}',
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text('Tidak ada gambar yang dipilih'),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: controller.pickImage,
                    icon: Icon(Icons.upload_file, color: Colors.black),
                    label: Text(
                      'Upload Bukti',
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Tombol Simpan
              ElevatedButton.icon(
                onPressed: _submit,
                icon: Icon(Icons.save),
                label: Text(editData != null ? 'Update' : 'Simpan Pengeluaran'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
