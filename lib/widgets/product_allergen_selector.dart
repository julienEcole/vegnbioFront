import 'package:flutter/material.dart';

/// Widget pour la sélection de produits ou allergènes avec autocomplétion
/// Permet de sélectionner des éléments existants ou d'en ajouter de nouveaux
class ProductAllergenSelector extends StatefulWidget {
  final String label;
  final List<String> selectedItems;
  final List<String> availableItems;
  final Function(List<String>) onChanged;
  final String hintText;
  final IconData icon;

  const ProductAllergenSelector({
    super.key,
    required this.label,
    required this.selectedItems,
    required this.availableItems,
    required this.onChanged,
    required this.hintText,
    required this.icon,
  });

  @override
  State<ProductAllergenSelector> createState() => _ProductAllergenSelectorState();
}

class _ProductAllergenSelectorState extends State<ProductAllergenSelector> {
  final TextEditingController _controller = TextEditingController();
  List<String> _filteredItems = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.availableItems;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.availableItems;
      } else {
        _filteredItems = widget.availableItems
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _showSuggestions = query.isNotEmpty && _filteredItems.isNotEmpty;
    });
  }

  void _addItem(String item) {
    if (item.trim().isNotEmpty && !widget.selectedItems.contains(item.trim())) {
      widget.onChanged([...widget.selectedItems, item.trim()]);
    }
    _controller.clear();
    setState(() {
      _showSuggestions = false;
    });
  }

  void _removeItem(String item) {
    widget.onChanged(widget.selectedItems.where((i) => i != item).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Champ de saisie avec autocomplétion
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(widget.icon),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addItem(_controller.text),
                    tooltip: 'Ajouter "${_controller.text}"',
                  )
                : null,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          onChanged: _filterItems,
          onSubmitted: (value) => _addItem(value),
        ),
        
        // Suggestions d'autocomplétion
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return ListTile(
                  dense: true,
                  title: Text(item),
                  onTap: () => _addItem(item),
                  trailing: const Icon(Icons.add, size: 16),
                );
              },
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Liste des éléments sélectionnés
        if (widget.selectedItems.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.selectedItems.map((item) {
              return Chip(
                label: Text(item),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeItem(item),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              );
            }).toList(),
          ),
        
        if (widget.selectedItems.isEmpty)
          Text(
            'Aucun ${widget.label.toLowerCase()} sélectionné',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
