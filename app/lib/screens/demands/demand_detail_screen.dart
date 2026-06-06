import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../models/demand.dart';
import '../../providers/demands_provider.dart';
import '../../providers/auth_provider.dart';

class DemandDetailScreen extends StatefulWidget {
  final Demand demand;

  const DemandDetailScreen({super.key, required this.demand});

  @override
  State<DemandDetailScreen> createState() => _DemandDetailScreenState();
}

class _DemandDetailScreenState extends State<DemandDetailScreen> {
  Demand? _demand;
  bool _showPhone = false;

  @override
  void initState() {
    super.initState();
    _demand = widget.demand;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final updated = await context.read<DemandsProvider>().loadDemandDetails(widget.demand.id);
    if (updated != null) {
      setState(() => _demand = updated);
    }
  }

  void _openMaps() async {
    final lat = _demand?.latitude;
    final lng = _demand?.longitude;
    if (lat != null && lng != null) {
      final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } else {
      final location = _demand?.location ?? '';
      final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  void _callPhone() async {
    final phone = _demand?.phone;
    if (phone != null) {
      final url = 'tel:$phone';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  void _showMakeOfferSheet() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour faire une offre')),
      );
      return;
    }

    final messageController = TextEditingController();
    final priceController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Faire une offre',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: 'Votre message *',
                  hintText: 'Décrivez votre offre...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'Prix proposé (optionnel)',
                  hintText: 'Ex: 5000',
                  suffixText: 'DZD',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (messageController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Le message est requis')),
                      );
                      return;
                    }
                    
                    setModalState(() => isSubmitting = true);
                    
                    final offer = await context.read<DemandsProvider>().createOffer(
                      demandId: _demand!.id,
                      message: messageController.text,
                      proposedPrice: double.tryParse(priceController.text),
                    );
                    
                    if (offer != null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Offre envoyée avec succès!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadDetails();
                    } else {
                      setModalState(() => isSubmitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.read<DemandsProvider>().error ?? 'Erreur'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Envoyer l\'offre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final demand = _demand!;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                demand.isOpen ? 'Ouverte' : 'Fermée',
                style: const TextStyle(fontSize: 14),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demand.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // Client info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: demand.displayImage != null
                                ? CachedNetworkImageProvider(demand.displayImage!)
                                : null,
                            child: demand.displayImage == null
                                ? Icon(Icons.person, color: Colors.grey.shade400)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Client', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(demand.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const Spacer(),
                          Text(demand.timeAgo ?? '', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Location
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.location_on,
                        iconColor: Colors.teal,
                        label: 'Adresse',
                        value: demand.location,
                        actionText: 'Voir sur maps',
                        onAction: _openMaps,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.phone,
                        iconColor: Colors.blue,
                        label: 'Téléphone',
                        value: _showPhone ? demand.phone : 'Voir le numéro',
                        onTap: () {
                          if (_showPhone) {
                            _callPhone();
                          } else {
                            setState(() => _showPhone = true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DÉTAILS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      Text(demand.description, style: const TextStyle(fontSize: 15, height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Action button
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: demand.isOpen ? _showMakeOfferSheet : null,
                          icon: const Icon(Icons.pan_tool),
                          label: const Text('Faire une offre'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Offers
                if (demand.offers.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OFFRES (${demand.offers.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cliquer sur un professionnel pour voir son profil complet',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 16),
                        ...demand.offers.map((offer) => _buildOfferCard(offer)),
                      ],
                    ),
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? actionText,
    VoidCallback? onAction,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          if (actionText != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionText, style: TextStyle(color: iconColor)),
            ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(DemandOffer offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: offer.isAccepted
              ? Colors.green.shade300
              : offer.isRejected
                  ? Colors.red.shade300
                  : Colors.grey.shade200,
          width: offer.isPending ? 1 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: offer.displayImage != null
                    ? CachedNetworkImageProvider(offer.displayImage!)
                    : null,
                child: offer.displayImage == null
                    ? Icon(Icons.person, color: Colors.grey.shade400)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          offer.displayName,
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                        if (offer.isAccepted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Acceptée', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ],
                        if (offer.isRejected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Refusée', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ],
                      ],
                    ),
                    if (offer.proposedPrice != null)
                      Text(
                        '${offer.proposedPrice!.toStringAsFixed(0)} DZD',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                      ),
                  ],
                ),
              ),
              Text(offer.timeAgo ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              offer.message,
              style: TextStyle(color: AppTheme.primaryColor.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}
