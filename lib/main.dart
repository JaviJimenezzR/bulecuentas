import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bulecuentas',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  String _result = '';
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _isProcessing = true;
        _result = 'Procesando imagen...';
      });
      await _processImage(File(pickedFile.path));
    }
  }

  Future<void> _processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    final String rawText = recognizedText.text;
    final List<RegExpMatch> matches =
    RegExp(r'\d{1,3}(?:[.,]\d{3})*[.,]\d{2}\s?[€€]', caseSensitive: false)
        .allMatches(rawText)
        .toList();

    double total = 0.0;
    List<String> amountsFound = [];

    for (var match in matches) {
      String matchText = match.group(0)!.replaceAll('€', '').replaceAll(' ', '');
      matchText = matchText.replaceAll('.', '').replaceAll(',', '.'); // Formato europeo
      double? value = double.tryParse(matchText);
      if (value != null) {
        total += value;
        amountsFound.add(value.toStringAsFixed(2));
      }
    }

    final formatCurrency = NumberFormat.currency(locale: 'es_ES', symbol: '€');

    setState(() {
      _isProcessing = false;
      _result = 'Total: ${formatCurrency.format(total)}\n';
      _result += 'Importes detectados (${amountsFound.length}):\n';
      _result += amountsFound.join(', ');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulecuentas')),
      body: Center(
        child: _isProcessing
            ? const CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_result, style: const TextStyle(fontSize: 18)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        tooltip: 'Seleccionar imagen',
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }
}
