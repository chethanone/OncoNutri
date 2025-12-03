import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// SearchableList - For cancer types and other searchable options
class SearchableList extends StatefulWidget {
  final List<String> items;
  final String placeholder;
  final Function(String) onSelect;
  final Map<String, List<String>>? groupedItems;

  const SearchableList({
    super.key,
    required this.items,
    this.placeholder = 'Search...',
    required this.onSelect,
    this.groupedItems,
  });

  @override
  State<SearchableList> createState() => _SearchableListState();
}

class _SearchableListState extends State<SearchableList> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;
    return widget.items
        .where((item) => item.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              prefixIcon: Icon(Icons.search, color: AppTheme.subtextColor(context)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.surfaceColor(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                borderSide: BorderSide(color: AppTheme.borderColor(context)),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              final item = _filteredItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: AppTheme.surfaceColor(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    onTap: () => widget.onSelect(item),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor(context)),
                        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.primary400Color(context),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item,
                              style: AppTheme.body,
                            ),
                          ),
                          Icon(
                            Icons.radio_button_unchecked,
                            color: AppTheme.borderColor(context),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// MultiSelectCardGrid - For symptoms and other multi-select options
class MultiSelectCardGrid extends StatelessWidget {
  final List<MultiSelectOption> options;
  final Set<String> selectedIds;
  final Function(Set<String>) onChange;
  final int crossAxisCount;

  const MultiSelectCardGrid({
    super.key,
    required this.options,
    required this.selectedIds,
    required this.onChange,
    this.crossAxisCount = 2,
  });

  void _toggleSelection(String id) {
    final newSelection = Set<String>.from(selectedIds);
    if (newSelection.contains(id)) {
      newSelection.remove(id);
    } else {
      newSelection.add(id);
    }
    onChange(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppTheme.gridGap,
        mainAxisSpacing: AppTheme.gridGap,
        childAspectRatio: 1.0,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selectedIds.contains(option.id);
        
        return GestureDetector(
          onTap: () => _toggleSelection(option.id),
          child: AnimatedContainer(
            duration: AppTheme.fadeInDuration,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFF7F4)
                  : AppTheme.surfaceColor(context),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor(context) : AppTheme.borderColor(context),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              boxShadow: isSelected ? AppTheme.selectedShadow : AppTheme.defaultShadow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (option.icon != null) ...[
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: option.icon,
                  ),
                  const SizedBox(height: 8),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    option.label,
                    style: AppTheme.bodyMedium.copyWith(fontSize: 14),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryColor(context),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MultiSelectOption {
  final String id;
  final String label;
  final Widget? icon;
  final String? meta;

  const MultiSelectOption({
    required this.id,
    required this.label,
    this.icon,
    this.meta,
  });
}

