import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  runApp(const AgroVisionApp());
}

class AgroVisionApp extends StatelessWidget {
  const AgroVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agro Vision',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class ScanHistoryItem {
  final String imagePath;
  final String result;
  final double confidence;
  final DateTime scannedAt;
  final String symptoms;
  final String cause;
  final String treatment;
  final String prevention;

  ScanHistoryItem({
    required this.imagePath,
    required this.result,
    required this.confidence,
    required this.scannedAt,
    required this.symptoms,
    required this.cause,
    required this.treatment,
    required this.prevention,
  });
}

class DiseaseInfo {
  final String modelLabel;
  final String name;
  final String symptoms;
  final String cause;
  final String treatment;
  final String prevention;

  const DiseaseInfo({
    required this.modelLabel,
    required this.name,
    required this.symptoms,
    required this.cause,
    required this.treatment,
    required this.prevention,
  });
}

class PredictionItem {
  final String label;
  final double score;

  PredictionItem({
    required this.label,
    required this.score,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;
  final List<ScanHistoryItem> history = [];

  final List<DiseaseInfo> library = const [
    DiseaseInfo(
      modelLabel: 'Pepper__bell__Bacterial_spot',
      name: 'Pepper Bell Bacterial Spot',
      symptoms:
          'Small water-soaked spots that become dark and irregular on leaves and fruits.',
      cause: 'Bacterial infection favored by warm, wet conditions.',
      treatment:
          'Remove infected leaves, avoid handling wet plants, and apply copper-based bactericide where appropriate.',
      prevention:
          'Use disease-free seeds, rotate crops, improve airflow, and avoid overhead irrigation.',
    ),
    DiseaseInfo(
      modelLabel: 'Pepper__bell__healthy',
      name: 'Pepper Bell Healthy',
      symptoms: 'No disease symptoms visible.',
      cause: 'Healthy plant condition.',
      treatment: 'No treatment needed. Continue good crop care.',
      prevention:
          'Maintain balanced watering, proper nutrition, and regular scouting.',
    ),
    DiseaseInfo(
      modelLabel: 'Potato__Early_blight',
      name: 'Potato Early Blight',
      symptoms:
          'Brown spots with concentric rings on older leaves and possible yellowing.',
      cause: 'Fungal infection caused by Alternaria.',
      treatment:
          'Remove heavily infected leaves, use recommended fungicide, and maintain field sanitation.',
      prevention:
          'Rotate crops, avoid overhead watering, and keep foliage dry where possible.',
    ),
    DiseaseInfo(
      modelLabel: 'Potato__Late_blight',
      name: 'Potato Late Blight',
      symptoms:
          'Dark, water-soaked lesions on leaves and stems, often spreading rapidly.',
      cause: 'Oomycete infection encouraged by cool, wet conditions.',
      treatment:
          'Remove infected plants quickly and apply appropriate fungicide immediately.',
      prevention:
          'Use certified seed, monitor humid weather, and destroy infected debris.',
    ),
    DiseaseInfo(
      modelLabel: 'Potato__healthy',
      name: 'Potato Healthy',
      symptoms: 'Leaves and stems appear normal and vigorous.',
      cause: 'Healthy plant condition.',
      treatment: 'No treatment needed. Continue normal management.',
      prevention:
          'Maintain proper nutrition, irrigation, and regular disease monitoring.',
    ),
    DiseaseInfo(
      modelLabel: 'Tomato_Bacterial_spot',
      name: 'Tomato Bacterial Spot',
      symptoms: 'Small dark lesions on leaves, stems, and fruits.',
      cause: 'Bacterial infection spread by splashing water and contaminated tools.',
      treatment:
          'Remove infected material and use suitable copper-based spray if recommended locally.',
      prevention:
          'Avoid wet foliage, disinfect tools, and use clean seed or transplants.',
    ),
    DiseaseInfo(
      modelLabel: 'Tomato_Early_blight',
      name: 'Tomato Early Blight',
      symptoms: 'Brown leaf spots with ring patterns, usually on older leaves.',
      cause: 'Fungal disease caused by Alternaria.',
      treatment:
          'Prune affected leaves, improve airflow, and apply fungicide where necessary.',
      prevention: 'Rotate crops, mulch around plants, and avoid overhead watering.',
    ),
    DiseaseInfo(
      modelLabel: 'Tomato_Late_blight',
      name: 'Tomato Late Blight',
      symptoms:
          'Large dark patches on leaves and stems, rapid blighting in wet conditions.',
      cause: 'Oomycete infection spread rapidly in cool, wet weather.',
      treatment:
          'Remove infected plants or leaves immediately and apply appropriate fungicide.',
      prevention:
          'Improve ventilation, avoid leaf wetness, and monitor weather closely.',
    ),
    DiseaseInfo(
      modelLabel: 'Tomato_Leaf_Mold',
      name: 'Tomato Leaf Mold',
      symptoms:
          'Yellow patches on upper leaf surfaces with mold growth underneath.',
      cause: 'Fungal pathogen favored by humid greenhouse or field conditions.',
      treatment: 'Remove infected leaves and reduce humidity around plants.',
      prevention:
          'Improve airflow, reduce overcrowding, and avoid prolonged leaf wetness.',
    ),
    DiseaseInfo(
      modelLabel: 'Tomato_Septoria_leaf_spot',
      name: 'Tomato Septoria Leaf Spot',
      symptoms: 'Small circular spots with dark borders and pale centers.',
      cause:
          'Fungal infection surviving on plant debris and spread by water splash.',
      treatment:
          'Remove infected leaves and apply fungicide if disease pressure is high.',
      prevention:
          'Rotate crops, stake plants, mulch soil, and keep leaves dry.',
    ),
    DiseaseInfo(
      modelLabel: 'Tomato_Spider_mites_Two_spotted_spider_mite',
      name: 'Tomato Spider Mites',
      symptoms: 'Fine speckling, yellowing, bronzing, and webbing on leaves.',
      cause:
          'Spider mite infestation, usually worse in hot and dry conditions.',
      treatment:
          'Wash leaves, remove badly affected leaves, and use suitable miticide if needed.',
      prevention: 'Reduce plant stress, monitor leaf undersides, and manage dust.',
    ),
    DiseaseInfo(
      modelLabel: 'Tomato__Target_Spot',
      name: 'Tomato Target Spot',
      symptoms: 'Brown lesions with ring-like target patterns on leaves.',
      cause: 'Fungal disease favored by warm and humid conditions.',
      treatment: 'Remove infected leaves and apply suitable fungicide.',
      prevention: 'Improve spacing, rotate crops, and avoid excess humidity.',
    ),
    DiseaseInfo(
      modelLabel: 'Tomato__Tomato_YellowLeaf_Curl_Virus',
      name: 'Tomato Yellow Leaf Curl Virus',
      symptoms:
          'Leaf curling, yellowing, reduced leaf size, and stunted growth.',
      cause: 'Virus spread mainly by whiteflies.',
      treatment:
          'There is no cure. Remove infected plants and control whiteflies.',
      prevention:
          'Use resistant varieties, control whiteflies early, and keep fields weed-free.',
    ),
    DiseaseInfo(
      modelLabel: 'Tomato__Tomato_mosaic_virus',
      name: 'Tomato Mosaic Virus',
      symptoms:
          'Mottled light and dark green leaves, distortion, and reduced vigor.',
      cause:
          'Viral infection spread by contaminated hands, tools, and plant material.',
      treatment: 'There is no cure. Remove infected plants and disinfect tools.',
      prevention:
          'Use clean seedlings, sanitize tools, and avoid handling plants after tobacco exposure.',
    ),
    DiseaseInfo(
      modelLabel: 'Tomato_healthy',
      name: 'Tomato Healthy',
      symptoms: 'Leaves are uniformly green and healthy-looking.',
      cause: 'Healthy plant condition.',
      treatment: 'No treatment needed. Continue normal care.',
      prevention:
          'Maintain good irrigation, nutrition, and regular field inspection.',
    ),
  ];

  void addToHistory(ScanHistoryItem item) {
    setState(() {
      history.insert(0, item);
      currentIndex = 3;
    });
  }

  int get healthyCount {
    return history.where((item) {
      final lower = item.result.toLowerCase();
      return lower.contains('healthy');
    }).length;
  }

  int get diseasedCount => history.length - healthyCount;

  @override
  Widget build(BuildContext context) {
    final latestScan = history.isNotEmpty ? history.first : null;

    final pages = [
      DashboardTab(
        history: history,
        healthyCount: healthyCount,
        diseasedCount: diseasedCount,
        onGoToDiagnose: () {
          setState(() {
            currentIndex = 1;
          });
        },
        onGoToLibrary: () {
          setState(() {
            currentIndex = 2;
          });
        },
        onGoToHistory: () {
          setState(() {
            currentIndex = 3;
          });
        },
        onGoToChatbot: () {
          setState(() {
            currentIndex = 4;
          });
        },
      ),
      DiagnoseTab(
        onSaved: addToHistory,
        library: library,
      ),
      LibraryTab(library: library),
      HistoryTab(history: history),
      ChatbotTab(
        library: library,
        latestScan: latestScan,
      ),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Diagnose',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'Chatbot',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  final List<ScanHistoryItem> history;
  final int healthyCount;
  final int diseasedCount;
  final VoidCallback onGoToDiagnose;
  final VoidCallback onGoToLibrary;
  final VoidCallback onGoToHistory;
  final VoidCallback onGoToChatbot;

  const DashboardTab({
    super.key,
    required this.history,
    required this.healthyCount,
    required this.diseasedCount,
    required this.onGoToDiagnose,
    required this.onGoToLibrary,
    required this.onGoToHistory,
    required this.onGoToChatbot,
  });

  String _formatConfidence(double c) {
    return '${(c * 100).toStringAsFixed(2)}%';
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 30, color: Colors.green),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.green, size: 30),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastScan = history.isNotEmpty ? history.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agro Vision Dashboard'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Agro Vision',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Detect plant diseases, review recommendations, track scan history, and ask the chatbot for help.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard('Total Scans', '${history.length}', Icons.analytics),
              const SizedBox(width: 10),
              _statCard('Healthy', '$healthyCount', Icons.check_circle),
            ],
          ),
          Row(
            children: [
              _statCard('Diseased', '$diseasedCount', Icons.warning),
              const SizedBox(width: 10),
              _statCard(
                'Last Confidence',
                lastScan != null ? _formatConfidence(lastScan.confidence) : '--',
                Icons.percent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lastScan != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(lastScan.imagePath),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Latest Scan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(lastScan.result),
                          const SizedBox(height: 4),
                          Text(
                            'Confidence: ${_formatConfidence(lastScan.confidence)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          _actionCard(
            title: 'Start New Scan',
            subtitle: 'Capture or upload a leaf image',
            icon: Icons.camera_alt,
            onTap: onGoToDiagnose,
          ),
          _actionCard(
            title: 'Disease Library',
            subtitle: 'View disease details and recommendations',
            icon: Icons.menu_book,
            onTap: onGoToLibrary,
          ),
          _actionCard(
            title: 'Scan History',
            subtitle: 'Review previous detections',
            icon: Icons.history,
            onTap: onGoToHistory,
          ),
          _actionCard(
            title: 'Chatbot Assistant',
            subtitle: 'Ask questions about the latest scan or any disease',
            icon: Icons.smart_toy,
            onTap: onGoToChatbot,
          ),
        ],
      ),
    );
  }
}

class DiagnoseTab extends StatefulWidget {
  final Function(ScanHistoryItem) onSaved;
  final List<DiseaseInfo> library;

  const DiagnoseTab({
    super.key,
    required this.onSaved,
    required this.library,
  });

  @override
  State<DiagnoseTab> createState() => _DiagnoseTabState();
}

class _DiagnoseTabState extends State<DiagnoseTab> {
  final ImagePicker _picker = ImagePicker();

  Interpreter? _interpreter;
  List<String> _labels = [];

  XFile? _selectedImage;
  List<PredictionItem> _topResults = [];
  DiseaseInfo? _detectedDisease;
  bool _loadingModel = true;
  bool _analyzing = false;
  String? _error;

  static const int inputSize = 224;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      final labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final modelData = await rootBundle.load('assets/agrovision_model.tflite');
      final modelBytes = modelData.buffer.asUint8List();

      final interpreter = Interpreter.fromBuffer(modelBytes);

      setState(() {
        _interpreter = interpreter;
        _labels = labels;
        _loadingModel = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load model: $e';
        _loadingModel = false;
      });
    }
  }

  String formatLabel(String label) {
    return label
        .replaceAll('__', ' ')
        .replaceAll('_', ' ')
        .replaceAll('  ', ' ')
        .trim();
  }

  DiseaseInfo? _findDiseaseInfo(String rawLabel) {
    try {
      return widget.library.firstWhere((item) => item.modelLabel == rawLabel);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 100);
    if (image == null) return;

    setState(() {
      _selectedImage = image;
      _topResults = [];
      _detectedDisease = null;
      _error = null;
    });
  }

  img.Image _prepareImage(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);

    if (decoded == null) {
      throw Exception('Could not decode image');
    }

    final baked = img.bakeOrientation(decoded);

    return img.copyResize(
      baked,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.average,
    );
  }

  List<List<List<List<double>>>> _imageToInputFloat(img.Image image) {
    return [
      List.generate(inputSize, (y) {
        return List.generate(inputSize, (x) {
          final pixel = image.getPixel(x, y);
          return [
            pixel.r.toDouble(),
            pixel.g.toDouble(),
            pixel.b.toDouble(),
          ];
        });
      }),
    ];
  }

  List<MapEntry<int, double>> _topPredictions(List<double> scores, int count) {
    final indexed = scores.asMap().entries
        .map((e) => MapEntry(e.key, e.value))
        .toList();

    indexed.sort((a, b) => b.value.compareTo(a.value));
    return indexed.take(count).toList();
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null || _interpreter == null) return;

    setState(() {
      _analyzing = true;
      _error = null;
    });

    try {
      final imageBytes = await File(_selectedImage!.path).readAsBytes();
      final processedImage = _prepareImage(imageBytes);
      final input = _imageToInputFloat(processedImage);

      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputShape = outputTensor.shape;
      final output = List.generate(
        outputShape[0],
        (_) => List.filled(outputShape[1], 0.0),
      );

      _interpreter!.run(input, output);

      final scores = List<double>.from(output[0]);
      final top3 = _topPredictions(scores, 3);

      final formattedTop3 = top3.map((item) {
        final raw = item.key < _labels.length ? _labels[item.key] : 'Unknown';
        final display = formatLabel(raw);
        return PredictionItem(label: display, score: item.value);
      }).toList();

      final bestIndex = top3.first.key;
      final rawBestLabel =
          bestIndex < _labels.length ? _labels[bestIndex] : 'Unknown';
      final displayBestLabel = formatLabel(rawBestLabel);
      final bestScore = top3.first.value;
      final diseaseInfo = _findDiseaseInfo(rawBestLabel);

      setState(() {
        _topResults = formattedTop3;
        _detectedDisease = diseaseInfo;
        _analyzing = false;
      });

      widget.onSaved(
        ScanHistoryItem(
          imagePath: _selectedImage!.path,
          result: displayBestLabel,
          confidence: bestScore,
          scannedAt: DateTime.now(),
          symptoms: diseaseInfo?.symptoms ?? 'No information available.',
          cause: diseaseInfo?.cause ?? 'No information available.',
          treatment: diseaseInfo?.treatment ?? 'No recommendation available.',
          prevention: diseaseInfo?.prevention ?? 'No prevention advice available.',
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Analysis failed: $e';
        _analyzing = false;
      });
    }
  }

  String _confidenceText(double value) {
    return '${(value * 100).toStringAsFixed(2)}%';
  }

  Widget _topResultTile(PredictionItem item, int rank) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text('$rank')),
      title: Text(item.label),
      subtitle: LinearProgressIndicator(value: item.score),
      trailing: Text(_confidenceText(item.score)),
    );
  }

  Widget _detailCard(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _selectedImage != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnose Plant'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Plant Disease Detection',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loadingModel ? 'Loading model...' : (_error ?? 'Model ready'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(16),
              ),
              child: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_selectedImage!.path),
                        fit: BoxFit.contain,
                      ),
                    )
                  : const Center(child: Text('No image selected')),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (!_loadingModel && hasImage && !_analyzing)
                    ? _analyzeImage
                    : null,
                icon: const Icon(Icons.search),
                label: Text(_analyzing ? 'Analyzing...' : 'Analyze Plant'),
              ),
            ),
            if (_topResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Predictions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _topResultTile(_topResults[0], 1),
                      if (_topResults.length > 1) _topResultTile(_topResults[1], 2),
                      if (_topResults.length > 2) _topResultTile(_topResults[2], 3),
                    ],
                  ),
                ),
              ),
            ],
            if (_detectedDisease != null) ...[
              _detailCard('Detected Disease', _detectedDisease!.name),
              _detailCard('Symptoms', _detectedDisease!.symptoms),
              _detailCard('Cause', _detectedDisease!.cause),
              _detailCard('Treatment Recommendation', _detectedDisease!.treatment),
              _detailCard('Prevention', _detectedDisease!.prevention),
            ],
            if (_error != null && !_loadingModel) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LibraryTab extends StatefulWidget {
  final List<DiseaseInfo> library;

  const LibraryTab({super.key, required this.library});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.library.where((item) {
      final q = query.toLowerCase();
      return item.name.toLowerCase().contains(q) ||
          item.symptoms.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Library'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search disease...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ExpansionTile(
                    leading: const Icon(Icons.local_florist, color: Colors.green),
                    title: Text(item.name),
                    childrenPadding: const EdgeInsets.all(16),
                    children: [
                      _infoRow('Symptoms', item.symptoms),
                      _infoRow('Cause', item.cause),
                      _infoRow('Treatment', item.treatment),
                      _infoRow('Prevention', item.prevention),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

class HistoryTab extends StatelessWidget {
  final List<ScanHistoryItem> history;

  const HistoryTab({super.key, required this.history});

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatConfidence(double c) {
    return '${(c * 100).toStringAsFixed(2)}%';
  }

  void _showDetails(BuildContext context, ScanHistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.result,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Confidence: ${_formatConfidence(item.confidence)}'),
                const SizedBox(height: 16),
                const Text(
                  'Symptoms',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 4),
                Text(item.symptoms),
                const SizedBox(height: 12),
                const Text(
                  'Cause',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 4),
                Text(item.cause),
                const SizedBox(height: 12),
                const Text(
                  'Treatment',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 4),
                Text(item.treatment),
                const SizedBox(height: 12),
                const Text(
                  'Prevention',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 4),
                Text(item.prevention),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
      ),
      body: history.isEmpty
          ? const Center(child: Text('No scan history yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(item.imagePath),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(item.result),
                    subtitle: Text(
                      'Confidence: ${_formatConfidence(item.confidence)}\n${_formatDate(item.scannedAt)}',
                    ),
                    isThreeLine: true,
                    onTap: () => _showDetails(context, item),
                  ),
                );
              },
            ),
    );
  }
}

class ChatbotTab extends StatefulWidget {
  final List<DiseaseInfo> library;
  final ScanHistoryItem? latestScan;

  const ChatbotTab({
    super.key,
    required this.library,
    required this.latestScan,
  });

  @override
  State<ChatbotTab> createState() => _ChatbotTabState();
}

class _ChatbotTabState extends State<ChatbotTab> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          'Hello, I am your Agro Vision assistant. You can ask about the latest scan, treatment, prevention, symptoms, causes, or diseases in the library.',
      isUser: false,
    ),
  ];

  @override
  void didUpdateWidget(covariant ChatbotTab oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  String _normalize(String text) {
    return text.toLowerCase().trim();
  }

  DiseaseInfo? _findDiseaseFromMessage(String message) {
    final query = _normalize(message);

    for (final disease in widget.library) {
      if (query.contains(disease.name.toLowerCase())) {
        return disease;
      }
      if (query.contains(disease.modelLabel.toLowerCase().replaceAll('_', ' '))) {
        return disease;
      }
    }

    final latest = widget.latestScan;
    if (latest != null) {
      for (final disease in widget.library) {
        if (disease.name.toLowerCase() == latest.result.toLowerCase()) {
          return disease;
        }
      }
    }

    return null;
  }

  String _buildLatestScanSummary() {
    final latest = widget.latestScan;
    if (latest == null) {
      return 'There is no latest scan yet. Please scan a plant image first.';
    }

    return 'Latest scan result: ${latest.result}. Confidence: ${(latest.confidence * 100).toStringAsFixed(2)}%. Symptoms: ${latest.symptoms}. Cause: ${latest.cause}. Treatment: ${latest.treatment}. Prevention: ${latest.prevention}.';
  }

  String _chatResponse(String userText) {
    final text = _normalize(userText);
    final latest = widget.latestScan;
    final disease = _findDiseaseFromMessage(userText);

    if (text.contains('latest scan') ||
        text.contains('last scan') ||
        text.contains('recent scan') ||
        text.contains('what was detected')) {
      return _buildLatestScanSummary();
    }

    if (text.contains('treatment') || text.contains('how do i treat')) {
      if (disease != null) {
        return 'Treatment for ${disease.name}: ${disease.treatment}';
      }
      if (latest != null) {
        return 'Treatment recommendation for the latest scan (${latest.result}): ${latest.treatment}';
      }
      return 'I do not have a detected disease yet. Scan a plant first or ask about a specific disease.';
    }

    if (text.contains('prevention') || text.contains('prevent')) {
      if (disease != null) {
        return 'Prevention for ${disease.name}: ${disease.prevention}';
      }
      if (latest != null) {
        return 'Prevention advice for the latest scan (${latest.result}): ${latest.prevention}';
      }
      return 'I do not have a disease to reference yet. Scan a plant first or mention a disease name.';
    }

    if (text.contains('symptom') || text.contains('sign')) {
      if (disease != null) {
        return 'Symptoms of ${disease.name}: ${disease.symptoms}';
      }
      if (latest != null) {
        return 'Symptoms for the latest scan (${latest.result}): ${latest.symptoms}';
      }
      return 'Please mention a disease name or scan a plant first.';
    }

    if (text.contains('cause') || text.contains('what causes')) {
      if (disease != null) {
        return 'Cause of ${disease.name}: ${disease.cause}';
      }
      if (latest != null) {
        return 'Cause of the latest scan (${latest.result}): ${latest.cause}';
      }
      return 'Please mention a disease name or scan a plant first.';
    }

    if (text.contains('healthy')) {
      final healthyDiseases = widget.library
          .where((d) => d.name.toLowerCase().contains('healthy'))
          .map((d) => d.name)
          .join(', ');
      return 'Healthy classes in the library are: $healthyDiseases';
    }

    if (text.contains('potato')) {
      final items = widget.library
          .where((d) => d.name.toLowerCase().contains('potato'))
          .map((d) => d.name)
          .join(', ');
      return 'Potato-related classes in the library: $items';
    }

    if (text.contains('tomato')) {
      final items = widget.library
          .where((d) => d.name.toLowerCase().contains('tomato'))
          .map((d) => d.name)
          .join(', ');
      return 'Tomato-related classes in the library: $items';
    }

    if (text.contains('pepper')) {
      final items = widget.library
          .where((d) => d.name.toLowerCase().contains('pepper'))
          .map((d) => d.name)
          .join(', ');
      return 'Pepper-related classes in the library: $items';
    }

    if (disease != null) {
      return 'Here is a summary for ${disease.name}. Symptoms: ${disease.symptoms}. Cause: ${disease.cause}. Treatment: ${disease.treatment}. Prevention: ${disease.prevention}.';
    }

    if (text.contains('help')) {
      return 'You can ask things like: "What was the latest scan?", "What is the treatment?", "How do I prevent tomato late blight?", "What are the symptoms of tomato mosaic virus?", or "Show me potato diseases."';
    }

    return 'I could not match that to a specific disease yet. Try asking about the latest scan, treatment, prevention, symptoms, cause, or mention a disease name from the library.';
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final response = _chatResponse(text);

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _messages.add(ChatMessage(text: response, isUser: false));
    });

    _controller.clear();
  }

  Widget _quickChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _controller.text = label;
        _sendMessage();
      },
    );
  }

  Widget _messageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.green.shade200 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latest = widget.latestScan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agro Vision Chatbot'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (latest != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Latest scan available: ${latest.result}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickChip('What was the latest scan?'),
                _quickChip('What is the treatment?'),
                _quickChip('How do I prevent this disease?'),
                _quickChip('Show me tomato diseases'),
                _quickChip('Show me potato diseases'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messageBubble(_messages[index]);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Ask about treatment, prevention, symptoms...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sendMessage,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}