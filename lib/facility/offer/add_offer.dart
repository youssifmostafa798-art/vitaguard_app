import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/components/custem_field.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/facility/data/facility_repository.dart';

class AddOffer extends StatefulWidget {
  const AddOffer({super.key});

  @override
  State<AddOffer> createState() => _AddOfferState();
}

class _AddOfferState extends State<AddOffer> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  final _repository = FacilityRepository();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    detailsController.dispose();
    discountController.dispose();
    priceController.dispose();
    super.dispose();
  }

  bool _isPicking = false;

  Future<void> _pickImage() async {
    if (_isPicking) return;
    try {
      _isPicking = true;
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } finally {
      _isPicking = false;
    }
  }

  Future<void> _saveOffer() async {
    if (nameController.text.trim().isEmpty ||
        detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill name and details")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Notes: Discount and Price are handled as part of details/description for now
      // as the backend FacilityOffer only has title and description.
      final fullDescription =
          "${detailsController.text}\nPrice: ${priceController.text}\nDiscount: ${discountController.text}%";

      await _repository.createOffer(
        title: nameController.text.trim(),
        description: fullDescription,
        image: _selectedImage,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Offer created successfully")),
      );
      Navigator.pop(context, nameController.text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to create offer: ${ErrorMapper.map(e)}"),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeader(title: "Add Offer"),
      body: SafeArea(
        child: AppBackground(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Gap(30),

                  CustemField(
                    title: "Display Name",
                    hint: "Summer Special",
                    controller: nameController,
                  ),
                  const Gap(20),

                  CustemField(
                    title: "Display Details",
                    hint: "Full body checkup with expert consultation",
                    controller: detailsController,
                  ),
                  const Gap(20),

                  Row(
                    children: [
                      Expanded(
                        child: CustemField(
                          title: "Discount %",
                          hint: "20",
                          controller: discountController,
                        ),
                      ),
                      const Gap(15),
                      Expanded(
                        child: CustemField(
                          title: "Original Price",
                          hint: "500",
                          controller: priceController,
                        ),
                      ),
                    ],
                  ),
                  const Gap(20),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Cover Image",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff0D3B66),
                      ),
                    ),
                  ),
                  const Gap(10),

                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xff0D3B66)),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 50,
                                    color: Color(0xff0D3B66),
                                  ),
                                  Gap(8),
                                  Text(
                                    "Select Offer Image",
                                    style: TextStyle(color: Color(0xff0D3B66)),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),

                  const Gap(50),

                  Button(
                    title: _isLoading ? "Saving..." : "Save",
                    onTap: _isLoading ? null : _saveOffer,
                  ),
                  const Gap(30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
