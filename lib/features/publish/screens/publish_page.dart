import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/api_service.dart';

class PublishPage extends StatefulWidget {
  const PublishPage({super.key});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final ApiService _api = ApiService();

  final PageController _pageController = PageController();
  int _currentStep = 0;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _uniqueIdController = TextEditingController();

  bool _isDonation = false;
  String? _selectedColor;
  String? _selectedCondition;
  String? _selectedCategory;
  double _conditionPercentage = 100.0;

  Map<String, File?> _categoryImages = {
    'Vue de face': null,
    'Vue arrière': null,
    'Vue de côté': null,
    'Vue détaillée': null,
    'Emballage': null,
  };

  bool _isLoading = false;

  bool _isAllowedFormat(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  bool _isAllowedSize(String path, {int maxBytes = 10 * 1024 * 1024}) {
    try {
      final f = File(path);
      return f.existsSync() ? f.lengthSync() <= maxBytes : false;
    } catch (_) {
      return false;
    }
  }

  void _nextStep() {
    if (_currentStep < 5) {
      setState(() => _currentStep++);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentStep == 5) {
      _submitAd();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitAd() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un titre'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez choisir une catégorie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_isDonation && _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un prix'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if ((_selectedCategory == 'Auto' ||
            _selectedCategory == 'Smartphone' ||
            _selectedCategory == 'Informatique' ||
            _selectedCategory == 'Gaming') &&
        _uniqueIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'L\'identifiant unique (${_selectedCategory == 'Auto' ? 'Châssis' : 'Série'}) est requis pour cette catégorie.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<File> photoFiles = [];
      for (var category in _categoryImages.values) {
        if (category != null) {
          photoFiles.add(category);
        }
      }
      if (photoFiles.length < 2) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Veuillez ajouter au moins les photos de face et arrière'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _api.createListing(
        title: _titleController.text,
        description: _descriptionController.text,
        price: _isDonation ? 0 : (double.tryParse(_priceController.text) ?? 0),
        color: _selectedColor ?? 'Non spécifié',
        condition: _selectedCondition ?? 'Bon état',
        conditionPercentage: _conditionPercentage.toInt(),
        uniqueId: _uniqueIdController.text.trim(),
        category: _selectedCategory ?? 'Autres',
        photos: photoFiles,
        firstName: _firstNameController.text.isNotEmpty
            ? _firstNameController.text
            : null,
        lastName: _lastNameController.text.isNotEmpty
            ? _lastNameController.text
            : null,
      );

      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        setState(() {
          _currentStep = 6;
        });
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            6,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: _previousStep,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close,
                color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                      color: Color(0xFF00897B), strokeWidth: 3),
                  SizedBox(height: 20),
                  Text('Chargement de la photo...',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 7,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF00897B)),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1QuickStart(),
                      _buildStep2Photos(),
                      _buildStep3Details(),
                      _buildStep4Description(),
                      _buildStep5Price(),
                      _buildStep6Coordinates(),
                      _buildStep7Success(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStep1QuickStart() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commençons par l\'essentiel !',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '*Champs obligatoires',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _titleController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Quel est le titre de votre annonce ? *',
              labelStyle: TextStyle(color: Theme.of(context).hintColor),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              style:
                  TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
              children: [
                TextSpan(
                  text: 'Me renseigner',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const TextSpan(
                  text:
                      ' sur les finalités du traitement de mes données personnelles, les destinataires, le responsable de traitement, les durées de conservation, les coordonnées du DPO et mes droits.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildStep2Photos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ajoutez des photos',
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Text(
              'Ajoutez un maximum de photos pour augmenter le nombre de contacts',
              style: TextStyle(color: Colors.grey[600], height: 1.5)),
          const SizedBox(height: 30),
          const Text(
            'Vos photos *',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.85,
            children: [
              _buildMainAddButton(),
              _buildPhotoSlot('Vue de face', Icons.smartphone, isCover: true),
              _buildPhotoSlot('Vue de côté', Icons.stay_current_portrait),
              _buildPhotoSlot('Vue arrière', Icons.camera_rear),
              _buildPhotoSlot('Vue détaillée', Icons.zoom_in),
              _buildPhotoSlot('Emballage', Icons.inventory_2_outlined),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_categoryImages['Vue de face'] != null &&
                      _categoryImages['Vue arrière'] != null)
                  ? _nextStep
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Continuer',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainAddButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 35, color: Color(0xFF1A3D63)),
          SizedBox(height: 10),
          Text(
            'Ajouter 20\nphotos',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3D63),
                fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlot(String label, IconData icon, {bool isCover = false}) {
    File? image = _categoryImages[label];
    return GestureDetector(
      onTap: () => _pickImageForCategory(label),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCover && image == null
                    ? const Color(0xFF1A3D63)
                    : Colors.grey.shade300,
                width: isCover && image == null ? 2 : 1,
              ),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(image, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 30, color: const Color(0xFF1A3D63)),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: const TextStyle(
                            color: Color(0xFF1A3D63),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
          ),
          if (isCover)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A3D63),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: const Text(
                  'Photo de couverture',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (image != null)
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _categoryImages[label] = null;
                  });
                },
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImageForCategory(String category) async {
    final picker = ImagePicker();
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFF6B35)),
              title: const Text("Prendre une photo"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? pickedFile =
                    await picker.pickImage(source: ImageSource.camera);
                if (!mounted) return;
                if (pickedFile != null) {
                  if (!_isAllowedFormat(pickedFile.path)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Format non supporté. Utilise JPG, JPEG, PNG ou WEBP.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (!_isAllowedSize(pickedFile.path)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fichier trop lourd (max 10 Mo).'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _categoryImages[category] = File(pickedFile.path);
                  });
                }
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFFFF6B35)),
              title: const Text("Choisir depuis la galerie"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? pickedFile =
                    await picker.pickImage(source: ImageSource.gallery);
                if (!mounted) return;
                if (pickedFile != null) {
                  if (!_isAllowedFormat(pickedFile.path)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Format non supporté. Utilise JPG, JPEG, PNG ou WEBP.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (!_isAllowedSize(pickedFile.path)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fichier trop lourd (max 10 Mo).'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _categoryImages[category] = File(pickedFile.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dites-nous en plus',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Mettez en valeur votre annonce !\nPlus il y a de détails, plus vos futurs contacts vous trouveront rapidement.',
            style: TextStyle(color: Theme.of(context).hintColor, height: 1.5),
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'Catégorie *',
            value: _selectedCategory,
            hint: 'Choisissez',
            onChanged: (value) => setState(() => _selectedCategory = value),
            items: const [
              'Immo',
              'Auto',
              'Vacances',
              'Smartphone',
              'Maison',
              'Sport',
              'Informatique',
              'Audio',
              'Gaming',
              'Autres'
            ],
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'Couleur',
            value: _selectedColor,
            hint: 'Choisissez',
            onChanged: (value) => setState(() => _selectedColor = value),
            items: ['Noir', 'Blanc', 'Bleu', 'Rouge', 'Vert', 'Rose', 'Gris'],
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'État *',
            value: _selectedCondition,
            hint: 'Choisissez un libellé',
            onChanged: (value) => setState(() => _selectedCondition = value),
            items: [
              'Neuf',
              'Très bon état',
              'Bon état',
              'État satisfaisant',
              'À réparer'
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Qualité de l\'état : ${_conditionPercentage.toInt()}%',
            style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor),
          ),
          Slider(
            value: _conditionPercentage,
            min: 1.0,
            max: 100.0,
            divisions: 99,
            activeColor: const Color(0xFF00897B),
            label: '${_conditionPercentage.toInt()}%',
            onChanged: (value) => setState(() => _conditionPercentage = value),
          ),
          if (_selectedCategory == 'Auto' ||
              _selectedCategory == 'Smartphone' ||
              _selectedCategory == 'Informatique' ||
              _selectedCategory == 'Gaming') ...[
            const SizedBox(height: 20),
            TextField(
              controller: _uniqueIdController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: _selectedCategory == 'Auto'
                    ? 'Numéro de châssis (VIN) *'
                    : _selectedCategory == 'Smartphone'
                        ? 'Numéro IMEI ou Série *'
                        : 'Numéro de série / Identifiant *',
                labelStyle: TextStyle(color: Theme.of(context).hintColor),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                helperText:
                    'Information unique pour garantir la sécurité de la transaction.',
              ),
            ),
          ],
          const SizedBox(height: 40),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hint,
    required ValueChanged<String?> onChanged,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Theme.of(context).hintColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
          dropdownColor: Theme.of(context).cardColor,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildStep4Description() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Décrivez votre bien !',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Mettez en valeur votre bien ! Plus il y a de détails, plus votre annonce sera de qualité. Détaillez ici ce qui a de l\'importance et ajoutera de la valeur.',
            style: TextStyle(color: Theme.of(context).hintColor, height: 1.5),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _titleController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Titre de l\'annonce *',
              labelStyle: TextStyle(color: Theme.of(context).hintColor),
              hintText: 'Ex: Samsung Galaxy A54',
              hintStyle: TextStyle(color: Theme.of(context).hintColor),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Vous n\'avez pas besoin de mentionner « Achat » ou « Vente » ici.',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text('Me proposer une description'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D40),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descriptionController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            maxLines: 6,
            maxLength: 4000,
            decoration: InputDecoration(
              labelText: 'Description de l\'annonce *',
              labelStyle: TextStyle(color: Theme.of(context).hintColor),
              hintText: 'Décrivez votre article en détail...',
              hintStyle: TextStyle(color: Theme.of(context).hintColor),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nous vous rappelons que la vente de contrefaçons est interdite. Nous vous invitons à ajouter tout élément permettant de prouver l\'authenticité de votre article: numéro de série, facture, certificat, inscription de la marque sur l\'article, emballage etc.',
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 10),
                Text(
                  'Indiquez dans le texte de l\'annonce si vous proposez un droit de rétractation à l\'acheteur. En l\'absence de toute mention, l\'acheteur n\'en bénéficiera pas et ne pourra pas demander le remboursement ou l\'échange du bien ou service proposé',
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildStep5Price() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quel est votre prix ?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Vous le savez, le prix est important. Soyez juste, mais ayez en tête une marge de négociation si besoin.',
            style: TextStyle(color: Theme.of(context).hintColor, height: 1.5),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Je fais un don',
                  style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface)),
              Switch(
                value: _isDonation,
                onChanged: (value) => setState(() => _isDonation = value),
                activeColor: const Color(0xFF00897B),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!_isDonation) ...[
            TextField(
              controller: _priceController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Votre prix de vente *',
                labelStyle: TextStyle(color: Theme.of(context).hintColor),
                suffixText: 'FCFA',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.card_giftcard,
                      color: Theme.of(context).primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Article offert gratuitement',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildStep6Coordinates() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vos coordonnées',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pour faciliter vos échanges avec vos futurs contacts, renseignez votre nom et prénom. Ils n\'apparaîtront pas sur l\'annonce.',
            style: TextStyle(color: Theme.of(context).hintColor, height: 1.5),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _lastNameController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Nom *',
              labelStyle: TextStyle(color: Theme.of(context).hintColor),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _firstNameController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Prénom *',
              labelStyle: TextStyle(color: Theme.of(context).hintColor),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 15),
          RichText(
            text: TextSpan(
              style:
                  TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
              children: const [
                TextSpan(
                    text:
                        'Vos nom et prénom n\'apparaîtront pas sur votre annonce. '),
                TextSpan(
                  text: 'Pourquoi est-ce important ?',
                  style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildContinueButton(label: 'Publier mon annonce'),
        ],
      ),
    );
  }

  Widget _buildStep7Success() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Text(
              'Nous avons bien reçu votre annonce !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Une fois contrôlée et validée, vous recevrez une notification et pourrez la retrouver dans la section « Annonces » de votre compte.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                height: 1.5,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                    _titleController.clear();
                    _descriptionController.clear();
                    _priceController.clear();
                    _lastNameController.clear();
                    _firstNameController.clear();
                    _isDonation = false;
                    _selectedColor = null;
                    _selectedCondition = null;
                    _selectedCategory = null;
                    _conditionPercentage = 100.0;
                    _uniqueIdController.clear();
                    _categoryImages = {
                      'Vue de face': null,
                      'Vue arrière': null,
                      'Vue de côté': null,
                      'Vue détaillée': null,
                      'Emballage': null,
                    };
                  });
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(0);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Déposer une nouvelle annonce',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF00897B)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Voir mes annonces',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton({String label = 'Continuer'}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _uniqueIdController.dispose();
    super.dispose();
  }
}
