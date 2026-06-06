import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/demands_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locations_provider.dart';
import '../../providers/categories_provider.dart';
import '../../models/location.dart';
import '../../models/category.dart';

class CreateDemandScreen extends StatefulWidget {
  const CreateDemandScreen({super.key});

  @override
  State<CreateDemandScreen> createState() => _CreateDemandScreenState();
}

class _CreateDemandScreenState extends State<CreateDemandScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  
  Wilaya? _selectedWilaya;
  Commune? _selectedCommune;
  Category? _selectedCategory;
  int? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isAnonymous = false;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    // Load wilayas and categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationsProvider>().loadWilayas();
      context.read<CategoriesProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position GPS obtenue'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur GPS: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCategoryPicker() {
    final categoriesProvider = context.read<CategoriesProvider>();
    final serviceCategories = categoriesProvider.serviceCategories;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Choisir une catégorie',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_selectedCategoryId != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = null;
                          _selectedCategoryId = null;
                          _selectedCategoryName = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Réinitialiser'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: serviceCategories.isEmpty
                  ? const Center(child: Text('Aucune catégorie de service disponible'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: serviceCategories.length,
                      itemBuilder: (context, index) {
                        final cat = serviceCategories[index];
                        return ExpansionTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(child: Text(cat.emoji ?? '🔧', style: const TextStyle(fontSize: 20))),
                          ),
                          title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${cat.children.length} sous-catégories'),
                          children: [
                            // Parent category option
                            ListTile(
                              contentPadding: const EdgeInsets.only(left: 72, right: 16),
                              title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: const Text('Catégorie principale', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              trailing: _selectedCategoryId == cat.id
                                  ? const Icon(Icons.check_circle, color: Colors.blue)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedCategory = cat;
                                  _selectedCategoryId = cat.id;
                                  _selectedCategoryName = cat.name;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            // Subcategories
                            ...cat.children.map((subcat) {
                              final isSelected = _selectedCategoryId == subcat.id;
                              return ListTile(
                                contentPadding: const EdgeInsets.only(left: 88, right: 16),
                                title: Text(subcat.name),
                                trailing: isSelected 
                                    ? const Icon(Icons.check_circle, color: Colors.blue)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = subcat;
                                    _selectedCategoryId = subcat.id;
                                    _selectedCategoryName = '${cat.name} > ${subcat.name}';
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitDemand() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez accepter les conditions d\'utilisation')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<DemandsProvider>();
      final demand = await provider.createDemand(
        title: _titleController.text,
        description: _descriptionController.text,
        phone: _phoneController.text,
        wilayaId: _selectedWilaya?.id,
        communeId: _selectedCommune?.id,
        latitude: _latitude,
        longitude: _longitude,
        serviceCategoryId: _selectedCategoryId,
        isAnonymous: _isAnonymous,
      );

      if (demand != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande publiée avec succès!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Erreur lors de la publication')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Nouvelle demande'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitDemand,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Publier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.thumb_up, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Décrivez votre besoin et recevez des offres de professionnels qualifiés!',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Title
            _buildLabel('Titre de la demande *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('Ex: Je cherche un plombier pour réparation'),
              validator: (v) => v?.isEmpty ?? true ? 'Le titre est requis' : null,
            ),
            const SizedBox(height: 20),

            // Description
            _buildLabel('Description détaillée *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration('Décrivez votre besoin en détail...'),
              maxLines: 4,
              validator: (v) => v?.isEmpty ?? true ? 'La description est requise' : null,
            ),
            const SizedBox(height: 20),

            // Category
            _buildLabel('Catégorie de service'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showCategoryPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedCategoryId != null ? Icons.check_circle : Icons.category,
                      color: _selectedCategoryId != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _selectedCategoryName != null
                          ? Text(_selectedCategoryName!, style: const TextStyle(fontWeight: FontWeight.w600))
                          : Text('Choisir une catégorie', style: TextStyle(color: Colors.grey.shade600)),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Phone
            _buildLabel('Numéro de téléphone *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              decoration: _inputDecoration('0555 XX XX XX'),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty ?? true ? 'Le téléphone est requis' : null,
            ),
            const SizedBox(height: 20),

            Consumer<LocationsProvider>(
              builder: (context, locations, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Wilaya *'),
                    const SizedBox(height: 8),
                    DropdownSearch<Wilaya>(
                      popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Rechercher une wilaya...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      items: (filter, props) => locations.wilayas,
                      itemAsString: (w) => '${w.code} - ${w.name}',
                      selectedItem: _selectedWilaya,
                      compareFn: (i, s) => i.id == s.id,
                      decoratorProps: DropDownDecoratorProps(
                        decoration: _inputDecoration('Sélectionner une wilaya'),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedWilaya = value;
                          _selectedCommune = null;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    if (_selectedWilaya != null) ...[
                      _buildLabel('Commune *'),
                      const SizedBox(height: 8),
                      DropdownSearch<Commune>(
                        key: ValueKey(_selectedWilaya!.id), // Reset state when wilaya changes
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Rechercher une commune...',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        items: (filter, props) async {
                          return await locations.getCommunes(_selectedWilaya!.id);
                        },
                        itemAsString: (c) => c.name,
                        selectedItem: _selectedCommune,
                        compareFn: (i, s) => i.id == s.id,
                        decoratorProps: DropDownDecoratorProps(
                          decoration: _inputDecoration('Sélectionner une commune'),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedCommune = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12), // Add spacing after commune if present
                    ]
                  ],
                );
              }
            ),

            // GPS button
            OutlinedButton.icon(
              onPressed: _getCurrentLocation,
              icon: Icon(Icons.gps_fixed, color: AppTheme.primaryColor),
              label: Text(
                _latitude != null ? 'Position GPS obtenue ✓' : 'Utiliser ma position GPS',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Anonymous toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility_off, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rester anonyme', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('Votre nom ne sera pas affiché', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAnonymous,
                    onChanged: (v) => setState(() => _isAnonymous = v),
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Terms checkbox
            Row(
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                  activeColor: AppTheme.primaryColor,
                ),
                const Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'J\'accepte les ',
                      children: [
                        TextSpan(
                          text: 'conditions d\'utilisation',
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitDemand,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Publier la demande', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
