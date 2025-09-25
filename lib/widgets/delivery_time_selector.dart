import 'package:flutter/material.dart';

class DeliveryTimeSelector extends StatefulWidget {
  final DateTime? selectedTime;
  final Function(DateTime?) onTimeSelected;
  final int minMinutesFromNow;

  const DeliveryTimeSelector({
    super.key,
    required this.selectedTime,
    required this.onTimeSelected,
    this.minMinutesFromNow = 15,
  });

  @override
  State<DeliveryTimeSelector> createState() => _DeliveryTimeSelectorState();
}

class _DeliveryTimeSelectorState extends State<DeliveryTimeSelector> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedTime;
    _selectedTime = widget.selectedTime != null 
        ? TimeOfDay.fromDateTime(widget.selectedTime!)
        : null;
    
    // Si aucun horaire n'est sélectionné, initialiser avec "aujourd'hui dans 25 minutes"
    if (_selectedDate == null && _selectedTime == null) {
      final DateTime defaultTime = DateTime.now().add(const Duration(minutes: 25));
      _selectedDate = defaultTime;
      _selectedTime = TimeOfDay.fromDateTime(defaultTime);
      
      // Notifier le parent de l'horaire par défaut
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTimeSelected(defaultTime);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Horaire de réception',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sélection de la date
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDate != null
                          ? _formatDate(_selectedDate!)
                          : 'Sélectionner une date',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Sélectionner une heure',
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informations sur les contraintes
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Délai minimum: ${widget.minMinutesFromNow} minutes à partir de maintenant',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (_selectedDate != null && _selectedTime != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isValidTime() ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isValidTime() ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isValidTime() ? Icons.check_circle : Icons.warning,
                      color: _isValidTime() ? Colors.green.shade700 : Colors.red.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isValidTime()
                            ? 'Horaire valide: ${_getFormattedDateTime()}'
                            : 'Horaire invalide: Trop proche du moment présent',
                        style: TextStyle(
                          color: _isValidTime() ? Colors.green.shade700 : Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateSelectedDateTime();
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _updateSelectedDateTime();
      });
    }
  }

  void _updateSelectedDateTime() {
    if (_selectedDate != null && _selectedTime != null) {
      final DateTime dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      
      if (_isValidTime()) {
        widget.onTimeSelected(dateTime);
      } else {
        widget.onTimeSelected(null);
      }
    } else {
      widget.onTimeSelected(null);
    }
  }

  bool _isValidTime() {
    if (_selectedDate == null || _selectedTime == null) return false;
    
    final DateTime selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    
    final DateTime now = DateTime.now();
    final DateTime minDateTime = now.add(Duration(minutes: widget.minMinutesFromNow));
    
    return selectedDateTime.isAfter(minDateTime);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Aujourd\'hui';
    } else if (dateOnly == tomorrow) {
      return 'Demain';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getFormattedDateTime() {
    if (_selectedDate == null || _selectedTime == null) return '';
    
    return '${_formatDate(_selectedDate!)} à ${_selectedTime!.format(context)}';
  }
}
