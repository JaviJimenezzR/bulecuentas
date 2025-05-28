import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
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
  List<Uint8List> _images = [];
  String _status = 'Selecciona imágenes para sumar los números detectados';
  double _total = 0;

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: true,
    );

    if (result != null) {
      final selectedImages = result.files
          .where((f) => f.bytes != null)
          .map((f) => f.bytes!)
          .toList();

      setState(() {
        _images = selectedImages;
        _status = 'Procesando imágenes...';
        _total = 0;
      });

      await _processImages(_images);
    } else {
      setState(() {
        _status = '❌ No se seleccionaron imágenes.';
      });
    }
  }

  Future<void> _processImages(List<Uint8List> images) async {
    double sum = 0;
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    for (final bytes in images) {
      final filePath = await _bytesToFile(bytes);
      final inputImage = InputImage.fromFilePath(filePath);

      final visionText = await textRecognizer.processImage(inputImage);
      final text = visionText.text;

      final numbers = RegExp(r'\d+([.,]\d+)?')
          .allMatches(text)
          .map((m) => m.group(0)!.replaceAll(',', '.'))
          .map((n) => double.tryParse(n))
          .where((n) => n != null)
          .cast<double>();

      sum += numbers.fold(0, (prev, el) => prev + el);
    }

    textRecognizer.close();

    setState(() {
      _status = '✅ Números detectados y sumados.';
      _total = sum;
    });
  }

  Future<String> _bytesToFile(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sumar totales de imágenes')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickImages,
              child: const Text('Seleccionar imágenes'),
            ),
            const SizedBox(height: 20),
            Text(_status),
            if (_images.isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) =>
                      Image.memory(_images[index], width: 100),
                ),
              ),
            const SizedBox(height: 20),
            if (_total > 0)
              Text(
                '🧮 Total detectado: $_total',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
