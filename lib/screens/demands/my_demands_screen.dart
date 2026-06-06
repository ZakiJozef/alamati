import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../models/demand.dart';
import '../../providers/demands_provider.dart';

class MyDemandsScreen extends StatefulWidget {
  const MyDemandsScreen({super.key});

  @override
  State<MyDemandsScreen> createState() => _MyDemandsScreenState();
}

class _MyDemandsScreenState extends State<MyDemandsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _offersLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DemandsProvider>().loadMyDemands();
    });
  }

  void _onTabChange() {
    if (_tabController.index == 1 && !_offersLoaded) {
      _offersLoaded = true;
      context.read<DemandsProvider>().loadMyOffers();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Mes Demandes'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Mes demandes', icon: Icon(Icons.work_outline, size: 20)),
            Tab(text: 'Mes offres', icon: Icon(Icons.handshake_outlined, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyDemandsTab(),
          _buildMyOffersTab(),
        ],
      ),
    );
  }

  Widget _buildMyDemandsTab() {
    return Consumer<DemandsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.myDemands.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.myDemands.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Aucune demande',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vos demandes apparaîtront ici',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadMyDemands(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.myDemands.length,
            itemBuilder: (context, index) {
              final demand = provider.myDemands[index];
              return _buildDemandCard(demand, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildDemandCard(Demand demand, DemandsProvider provider) {
    // Get status color
    Color statusColor;
    if (demand.isOpen) {
      statusColor = Colors.green;
    } else if (demand.isInProcess) {
      statusColor = Colors.blue;
    } else if (demand.isCompleted) {
      statusColor = Colors.purple;
    } else if (demand.isCanceled) {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    demand.statusText,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    demand.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildDemandActions(demand, provider),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(demand.location, style: TextStyle(color: Colors.grey.shade600)),
                    const Spacer(),
                    Text(demand.timeAgo ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  demand.description,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // In Process: Show complete/cancel buttons
          if (demand.isInProcess)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(demand, provider),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Annuler'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showCompleteDialog(demand, provider),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Terminer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Offers section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.handshake, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${demand.offers.length} offre(s) reçue(s)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                if (demand.offers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...demand.offers.map((offer) => _buildOfferItem(offer, demand, provider)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandActions(Demand demand, DemandsProvider provider) {
    if (demand.isOpen) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) async {
          if (value == 'close') {
            _showCloseDialog(demand, provider);
          } else if (value == 'delete') {
            _showDeleteDialog(demand, provider);
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'close', child: Row(children: [Icon(Icons.close), SizedBox(width: 8), Text('Fermer')])),
          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Colors.red))])),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _showCloseDialog(Demand demand, DemandsProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fermer la demande?'),
        content: const Text('Vous ne recevrez plus d\'offres sur cette demande.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Fermer')),
        ],
      ),
    );
    if (confirm == true) {
      await provider.closeDemand(demand.id);
    }
  }

  Future<void> _showDeleteDialog(Demand demand, DemandsProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la demande?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await provider.deleteDemand(demand.id);
    }
  }

  Future<void> _showCompleteDialog(Demand demand, DemandsProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminer la demande?'),
        content: const Text('Confirmer que le travail a été effectué avec succès.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await provider.completeDemand(demand.id);
    }
  }

  Future<void> _showCancelDialog(Demand demand, DemandsProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la demande?'),
        content: const Text('Vous annulez cette demande. Le prestataire sera notifié.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Retour')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Annuler la demande', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await provider.cancelDemand(demand.id);
    }
  }


  Widget _buildOfferItem(DemandOffer offer, Demand demand, DemandsProvider provider) {
    Color statusColor = offer.isAccepted ? Colors.green : offer.isRejected ? Colors.red : Colors.orange;
    String statusText = offer.isAccepted ? 'Acceptée' : offer.isRejected ? 'Refusée' : 'En attente';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: offer.displayImage != null ? CachedNetworkImageProvider(offer.displayImage!) : null,
                child: offer.displayImage == null ? Icon(Icons.person, color: Colors.grey.shade400, size: 20) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (offer.proposedPrice != null)
                      Text('${offer.proposedPrice!.toStringAsFixed(0)} DZD', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(offer.message, style: TextStyle(color: Colors.grey.shade700)),
          ),
          if (offer.isPending && demand.isOpen) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await provider.rejectOffer(offer.id);
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await provider.acceptOffer(offer.id);
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accepter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyOffersTab() {
    return Consumer<DemandsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.myOffers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.myOffers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.handshake_outlined, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Aucune offre envoyée',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vos offres sur les demandes apparaîtront ici',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadMyOffers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.myOffers.length,
            itemBuilder: (context, index) {
              final offer = provider.myOffers[index];
              return _buildMyOfferCard(offer);
            },
          ),
        );
      },
    );
  }

  Widget _buildMyOfferCard(DemandOffer offer) {
    Color statusColor = offer.isAccepted 
        ? Colors.green 
        : offer.isRejected 
            ? Colors.red 
            : Colors.orange;
    String statusText = offer.isAccepted 
        ? 'Acceptée ✓' 
        : offer.isRejected 
            ? 'Refusée' 
            : 'En attente...';
    IconData statusIcon = offer.isAccepted 
        ? Icons.check_circle 
        : offer.isRejected 
            ? Icons.cancel 
            : Icons.hourglass_empty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Statut: $statusText',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (offer.proposedPrice != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${offer.proposedPrice!.toStringAsFixed(0)} DZD',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          // Demand info
          if (offer.demand != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DEMANDE',
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    offer.demand!.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        offer.demand!.location,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: offer.demand!.isOpen ? Colors.green.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          offer.demand!.isOpen ? 'Ouverte' : 'Fermée',
                          style: TextStyle(
                            fontSize: 11,
                            color: offer.demand!.isOpen ? Colors.green.shade700 : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Your offer message
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.message, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Votre offre',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (offer.isPending) ...[
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        color: AppTheme.primaryColor,
                        onPressed: () => _showEditOfferDialog(offer),
                        tooltip: 'Modifier',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        color: Colors.red,
                        onPressed: () => _showDeleteOfferDialog(offer),
                        tooltip: 'Supprimer',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  offer.message,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                if (offer.proposedPrice != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Prix proposé: ${offer.proposedPrice!.toStringAsFixed(0)} DZD',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                  ),
                ],
              ],
            ),
          ),

          // Accepted message
          if (offer.isAccepted)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration, color: Colors.green, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Félicitations!',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        Text(
                          'Votre offre a été acceptée. Contactez le client pour finaliser.',
                          style: TextStyle(fontSize: 13, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showEditOfferDialog(DemandOffer offer) async {
    final messageController = TextEditingController(text: offer.message);
    final priceController = TextEditingController(
      text: offer.proposedPrice?.toStringAsFixed(0) ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier votre offre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Prix proposé (DZD)',
                border: OutlineInputBorder(),
                prefixText: 'DZD ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result == true) {
      final provider = context.read<DemandsProvider>();
      await provider.updateOffer(
        offer.id,
        message: messageController.text,
        proposedPrice: double.tryParse(priceController.text),
      );
    }
  }

  Future<void> _showDeleteOfferDialog(DemandOffer offer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette offre?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = context.read<DemandsProvider>();
      await provider.deleteOffer(offer.id);
    }
  }
}
