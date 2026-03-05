import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';


class FontScannerPage extends StatefulWidget {
  const FontScannerPage({super.key});

  @override
  State<FontScannerPage> createState() => _FontScannerPageState();
}

class _FontScannerPageState extends State<FontScannerPage> {
  File? _imageFile;
  String _recognizedText = '';
  String _selectedFontFamily = 'Poppins';
  bool _isProcessing = false;

  final TextEditingController _customTextController = TextEditingController();

  // Yaha wo fonts rakho jo tumne pubspec.yaml me define kiye hain
  final List<String> _availableFonts = [
    'Poppins',
    'Roboto',
    'Lato',
    'OpenSans',
  ];

  @override
  void dispose() {
    _customTextController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile =
      await picker.pickImage(source: source, imageQuality: 90);

      if (pickedFile == null) return;

      setState(() {
        _imageFile = File(pickedFile.path);
        _recognizedText = '';
        _isProcessing = true;
      });

      await _runTextRecognition(pickedFile.path);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _recognizedText = 'Error while picking image: $e';
      });
    }
  }

  Future<void> _runTextRecognition(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();

    try {
      final RecognizedText recognizedText =
      await textRecognizer.processImage(inputImage);

      final String fullText = recognizedText.text;

      setState(() {
        _recognizedText =
        fullText.isEmpty ? 'No text detected.' : fullText;

        // Agar user ne abhi tak custom text nahi likha,
        // to OCR se aaya hua text hi custom text bana do
        if (_customTextController.text.trim().isEmpty &&
            fullText.isNotEmpty) {
          _customTextController.text = fullText;
        }
      });
    } catch (e) {
      setState(() {
        _recognizedText = 'Error while recognizing text: $e';
      });
    } finally {
      await textRecognizer.close();
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Widget _buildImageSection() {
    if (_imageFile == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: const Text('Koi image select nahi ki gayi'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        _imageFile!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildFontPreviewList() {
    final text = _customTextController.text.isEmpty
        ? 'Sample Text'
        : _customTextController.text;

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _availableFonts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final font = _availableFonts[index];
          final isSelected = font == _selectedFontFamily;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFontFamily = font;
              });
            },
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    font,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                      isSelected ? Colors.blue.shade800 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Center(
                      child: Text(
                        text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedText = _customTextController.text.isEmpty
        ? 'Yaha custom text ka preview aayega'
        : _customTextController.text;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Text → Custom Font'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Image preview
              _buildImageSection(),
              const SizedBox(height: 12),

              // Buttons row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo),
                      label: const Text('Gallery se lo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera se lo'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (_isProcessing)
                const LinearProgressIndicator(),

              // OCR result
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_recognizedText.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Image se nikla hua text:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            _recognizedText,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Custom text input
                      TextField(
                        controller: _customTextController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          labelText: 'Apna custom text likho',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Font choose karo (image wale se closest):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      _buildFontPreviewList(),
                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Final preview (selected font):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          color: Colors.grey.shade100,
                        ),
                        child: Text(
                          selectedText,
                          style: TextStyle(
                            fontFamily: _selectedFontFamily,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}