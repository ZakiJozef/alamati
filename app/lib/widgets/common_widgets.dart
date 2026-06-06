import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/store.dart';
import '../providers/stores_provider.dart';
import 'store_card.dart';

/// Instagram-style search bar with suggestions dropdown
class SearchWithSuggestions extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onQRTap;
  final VoidCallback? onSubmitted;
  final void Function(Store store)? onStoreTap;

  const SearchWithSuggestions({
    super.key,
    this.hintText = 'Search for services or stores...',
    this.controller,
    this.onChanged,
    this.onFilterTap,
    this.onQRTap,
    this.onSubmitted,
    this.onStoreTap,
  });

  @override
  State<SearchWithSuggestions> createState() => _SearchWithSuggestionsState();
}

class _SearchWithSuggestionsState extends State<SearchWithSuggestions> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // Delay hiding to allow tap on suggestions
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            child: Consumer<StoresProvider>(
              builder: (context, provider, _) {
                final suggestions = provider.searchSuggestions;
                final isLoading = provider.isLoadingSuggestions;
                final query = widget.controller?.text ?? '';

                // Don't show if query is too short
                if (query.length < 2) {
                  return const SizedBox.shrink();
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: isLoading && suggestions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : suggestions.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No stores found for "$query"',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: suggestions.length,
                                itemBuilder: (context, index) {
                                  final store = suggestions[index];
                                  return _SuggestionTile(
                                    store: store,
                                    onTap: () {
                                      _focusNode.unfocus();
                                      _removeOverlay();
                                      provider.clearSuggestions();
                                      widget.onStoreTap?.call(store);
                                    },
                                  );
                                },
                              ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    widget.onChanged?.call(value);
    final provider = context.read<StoresProvider>();
    provider.searchForSuggestions(value);
    
    // Rebuild overlay to show/hide based on query length
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hasFocus ? AppTheme.primaryColor : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            if (_hasFocus)
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 1,
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          onSubmitted: (_) {
            context.read<StoresProvider>().clearSuggestions();
            widget.onSubmitted?.call();
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: _hasFocus ? AppTheme.primaryColor : Colors.grey.shade400,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clear button when there's text
                if (widget.controller?.text.isNotEmpty ?? false)
                  GestureDetector(
                    onTap: () {
                      widget.controller?.clear();
                      _onSearchChanged('');
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.close,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                    ),
                  ),
                // QR Scanner button
                if (widget.onQRTap != null)
                  GestureDetector(
                    onTap: widget.onQRTap,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: Colors.grey.shade500,
                        size: 22,
                      ),
                    ),
                  ),
                // Filter button
                GestureDetector(
                  onTap: widget.onFilterTap,
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        ),
      ),
    );
  }
}

/// Instagram-style suggestion tile with profile picture
class _SuggestionTile extends StatelessWidget {
  final Store store;
  final VoidCallback? onTap;

  const _SuggestionTile({
    required this.store,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Profile Picture with gradient ring (Instagram style)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: store.profileImage != null && store.profileImage!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: store.profileImage!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.store, color: Colors.grey.shade400),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.store, color: Colors.grey.shade400),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Icon(Icons.store, color: Colors.grey.shade400, size: 24),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Store info - takes all remaining space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store name (bold, like username)
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Category (subtitle)
                  if (store.category != null)
                    Text(
                      store.category!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  // Bottom row: Location + Rating
                  Row(
                    children: [
                      // Location
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          store.location,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Rating badge (at the right of the bottom row)
                      if (store.rating > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                store.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onQRTap;
  final VoidCallback? onSubmitted;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search for services or stores...',
    this.controller,
    this.onChanged,
    this.onFilterTap,
    this.onQRTap,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted?.call(),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade400,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // QR Scanner button
              if (onQRTap != null)
                GestureDetector(
                  onTap: onQRTap,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                  ),
                ),
              // Filter button
              GestureDetector(
                onTap: onFilterTap,
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}


class CustomFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const CustomFilterChip({
    super.key,
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppTheme.primaryColor) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade900,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              color: Colors.grey.shade400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class ViewToggleButton extends StatelessWidget {
  final bool isGridView; // For backwards compatibility
  final CardViewType? viewType;
  final VoidCallback? onToggle;

  const ViewToggleButton({
    super.key,
    this.isGridView = true, // Deprecated but kept for backwards compat
    this.viewType,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Use viewType if provided, otherwise fall back to isGridView
    final currentType = viewType ?? (isGridView ? CardViewType.grid : CardViewType.list);
    
    IconData icon;
    switch (currentType) {
      case CardViewType.grid:
        icon = Icons.grid_view_rounded;
        break;
      case CardViewType.list:
        icon = Icons.view_list_rounded;
        break;
      case CardViewType.detailed:
        icon = Icons.view_agenda_rounded;
        break;
    }
    
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.grey.shade700,
          size: 20,
        ),
      ),
    );
  }
}

class CategoryBadge extends StatelessWidget {
  final String category;
  final bool isLarge;

  const CategoryBadge({
    super.key,
    required this.category,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getCategoryColor(category);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 8,
        vertical: isLarge ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isLarge ? 8 : 4),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          fontSize: isLarge ? 12 : 9,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
