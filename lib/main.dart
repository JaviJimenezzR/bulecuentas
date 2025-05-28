import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'Selecciona imágenes con números (€)';
  List<Uint8List> _images = [];
  double _total = 0.0;

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      _images.clear();
      _total = 0.0;
      setState(() {
        _status = 'Procesando ${result.files.length} imagen(es)...';
      });

      final recognizer = TextRecognizer();

      for (final file in result.files) {
        if (file.bytes != null) {
          _images.add(file.bytes!);

          final inputImage = InputImage.fromFilePath(file.path!);

          final RecognizedText recognizedText = await recognizer.processImage(inputImage);

          _extractAndSumPrices(recognizedText.text);
        }
      }

      recognizer.close();

      setState(() {
        _status = '✅ Suma total: ${_total.toStringAsFixed(2)} €';
      });
    } else {
      setState(() {
        _status = '❌ No se seleccionó ninguna imagen.';
      });
    }
  }

  void _extractAndSumPrices(String text) {
    // Busca cualquier número con € delante o detrás
    final regExp = RegExp(r'(?:€\s?|(?<=\s))(\d+[.,]?\d*)(?:\s?€)?');

    final matches = regExp.allMatches(text);

    for (final match in matches) {
      String matchStr = match.group(1) ?? '';
      matchStr = matchStr.replaceAll(',', '.').trim();

      final value = double.tryParse(matchStr);
      if (value != null) {
        _total += value;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suma de cantidades €')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _pickImages,
                child: const Text('Seleccionar imágenes'),
              ),
              const SizedBox(height: 20),
              if (_images.isNotEmpty)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _images
                      .map((img) => Image.memory(img, width: 100, height: 100, fit: BoxFit.cover))
                      .toList(),
                ),
              const SizedBox(height: 20),
              Text(_status, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
