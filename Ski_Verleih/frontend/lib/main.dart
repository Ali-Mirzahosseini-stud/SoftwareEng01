import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'api.dart';
import 'models.dart';

void main() => runApp(const SkiVerleihApp());

class SkiVerleihApp extends StatelessWidget {
  const SkiVerleihApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff18324a);
    return MaterialApp(
      title: 'Ski-Verleih',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff247ba0),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff3f7fa),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final api = SkiApi();
  final dashboardKey = GlobalKey();
  final itemsKey = GlobalKey();
  final peopleKey = GlobalKey();
  final rentalsKey = GlobalKey();

  Dashboard? dashboard;
  List<RentalItem> items = [];
  List<Customer> customers = [];
  List<Rental> rentals = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final result = await Future.wait<dynamic>([
        api.getDashboard(),
        api.getItems(),
        api.getCustomers(),
        api.getRentals(),
      ]);
      if (!mounted) return;
      setState(() {
        dashboard = result[0] as Dashboard;
        items = result[1] as List<RentalItem>;
        customers = result[2] as List<Customer>;
        rentals = result[3] as List<Rental>;
        loading = false;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = exception.toString();
      });
    }
  }

  void _jumpTo(GlobalKey key) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.04,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _ErrorView(message: error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                    children: [
                      _HeroHeader(
                        onRent: _showRentalDialog,
                        onCustomer: _showCustomerDialog,
                      ),
                      const SizedBox(height: 28),
                      _section(
                        key: dashboardKey,
                        title: 'Übersicht',
                        subtitle: 'Der aktuelle Stand deines Ski-Verleihs.',
                        child: _StatsGrid(data: dashboard!),
                      ),
                      const SizedBox(height: 24),
                      _section(
                        key: itemsKey,
                        title: 'Ski-Verwaltung',
                        subtitle: 'Bestand und Verfügbarkeit auf einen Blick.',
                        child: _ItemsTable(items: items),
                      ),
                      const SizedBox(height: 24),
                      _section(
                        key: peopleKey,
                        title: 'Personen',
                        subtitle: 'Registrierte Kunden mit Ausweisdaten.',
                        trailing: OutlinedButton.icon(
                          onPressed: _showCustomerDialog,
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
                          label: const Text('Person hinzufügen'),
                        ),
                        child: _CustomersTable(customers: customers),
                      ),
                      const SizedBox(height: 24),
                      _section(
                        key: rentalsKey,
                        title: 'Reservierungen & Ausleihen',
                        subtitle: 'Aktive Ausleihen verwalten und abschließen.',
                        trailing: FilledButton.icon(
                          onPressed: _showRentalDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Neue Ausleihe'),
                        ),
                        child: _RentalsTable(
                          rentals: rentals
                              .where((rental) => rental.endedAt == null)
                              .toList(),
                          items: items,
                          customers: customers,
                          onEnd: _endRental,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final compact = MediaQuery.sizeOf(context).width < 1000;
    return AppBar(
      toolbarHeight: 72,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.downhill_skiing, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Ski-Verleih',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
          ),
        ],
      ),
      actions: [
        _NavButton(
            label: 'Dashboard',
            icon: Icons.dashboard_outlined,
            compact: compact,
            onTap: () => _jumpTo(dashboardKey)),
        _NavButton(
            label: 'Ski-Verwaltung',
            icon: Icons.downhill_skiing,
            compact: compact,
            onTap: () => _jumpTo(itemsKey)),
        _NavButton(
            label: 'Personen',
            icon: Icons.people_outline,
            compact: compact,
            onTap: () => _jumpTo(peopleKey)),
        _NavButton(
            label: 'Reservierungen',
            icon: Icons.event_note_outlined,
            compact: compact,
            onTap: () => _jumpTo(rentalsKey)),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Daten aktualisieren',
          onPressed: _load,
          icon: const Icon(Icons.refresh),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _section({
    required GlobalKey key,
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe1eaf0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0b18324a),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xff18324a),
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xff6d8290)),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1, color: Color(0xffe8eef2)),
          ),
          child,
        ],
      ),
    );
  }

  Future<void> _showCustomerDialog() async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (_) => CustomerDialog(api: api),
    );
    if (result != null) await _load();
  }

  Future<void> _showRentalDialog() async {
    final available = items.where((item) => !item.isRented).toList();
    if (available.isEmpty || customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Für eine Ausleihe werden ein verfügbarer Ski und ein Kunde benötigt.'),
        ),
      );
      return;
    }
    final result = await showDialog<Rental>(
      context: context,
      builder: (_) =>
          RentalDialog(api: api, items: items, customers: customers),
    );
    if (result != null) await _load();
  }

  Future<void> _endRental(Rental rental) async {
    try {
      final result = await api.endRental(
        rentalId: rental.id,
        endedAt: DateTime.now(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Ausleihe beendet: ${result.totalPrice.toStringAsFixed(2)} € für ${result.billedHours} Stunden.',
          ),
        ),
      );
      await _load();
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(exception.toString())),
        );
      }
    }
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        onPressed: onTap,
        tooltip: label,
        icon: Icon(icon, size: 18),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        style: IconButton.styleFrom(
          foregroundColor: Colors.white.withValues(alpha: 0.9),
        ),
      );
    }
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.9),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.onRent, required this.onCustomer});

  final VoidCallback onRent;
  final VoidCallback onCustomer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 24, 50, 74), Color.fromARGB(255, 36, 123, 160)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 22,
        children: [
          const SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Willkommen im Ski-Verleih',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Verwalte deinen Bestand, Kunden und Ausleihen schnell und übersichtlich.',
                  style: TextStyle(color: Color(0xffd9edf4), fontSize: 15),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onRent,
                icon: const Icon(Icons.add),
                label: const Text('Neue Ausleihe'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 54, 197, 183),
                  foregroundColor: const Color(0xff18324a),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onCustomer,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Person registrieren'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color.fromARGB(153, 255, 255, 255)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data});

  final Dashboard data;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        'Verfügbare Ski',
        '${data.availableItems}',
        Icons.check_circle_outline,
        const Color.fromARGB(255, 7, 61, 84)
      ),
      (
        'Ausgeliehene Ski',
        '${data.rentedItems}',
        Icons.snowboarding,
        const Color.fromARGB(255, 212, 59, 92)
      ),
      (
        'Gesamtbestand',
        '${data.totalItems}',
        Icons.inventory_2_outlined,
        const Color.fromARGB(255, 184, 121, 28)
      ),
      (
        'Registrierte Personen',
        '${data.registeredCustomers}',
        Icons.people_outline,
        const Color.fromARGB(255, 20, 133, 88)
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 560
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 2.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: stats
              .map(
                (stat) => _StatCard(
                  label: stat.$1,
                  value: stat.$2,
                  icon: stat.$3,
                  color: stat.$4,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            foregroundColor: Colors.white,
            child: Icon(icon, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff526b7a),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.items});

  final List<RentalItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(text: 'Noch keine Ski vorhanden.');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xfff3f7fa)),
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Typ')),
          DataColumn(label: Text('Stundensatz')),
          DataColumn(label: Text('Status')),
        ],
        rows: items
            .map(
              (item) => DataRow(
                cells: [
                  DataCell(Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(item.type)),
                  DataCell(Text('${item.hourlyRate.toStringAsFixed(2)} € / h')),
                  DataCell(_StatusBadge(rented: item.isRented)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CustomersTable extends StatelessWidget {
  const _CustomersTable({required this.customers});

  final List<Customer> customers;

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return const _EmptyState(text: 'Noch keine Personen registriert.');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xfff3f7fa)),
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Ausweistyp')),
          DataColumn(label: Text('Ausweisnummer')),
        ],
        rows: customers
            .map(
              (customer) => DataRow(
                cells: [
                  DataCell(Text(customer.name,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(customer.documentType)),
                  DataCell(Text(customer.documentNumber)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RentalsTable extends StatelessWidget {
  const _RentalsTable({
    required this.rentals,
    required this.items,
    required this.customers,
    required this.onEnd,
  });

  final List<Rental> rentals;
  final List<RentalItem> items;
  final List<Customer> customers;
  final ValueChanged<Rental> onEnd;

  @override
  Widget build(BuildContext context) {
    if (rentals.isEmpty) {
      return const _EmptyState(text: 'Keine aktiven Ausleihen.');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xfff3f7fa)),
        columns: const [
          DataColumn(label: Text('Ski')),
          DataColumn(label: Text('Kunde')),
          DataColumn(label: Text('Dauer')),
          DataColumn(label: Text('Preis (geplant)')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Aktion')),
        ],
        rows: rentals.map((rental) {
          final item = _findItem(rental.itemId);
          final customer = _findCustomer(rental.customerId);
          final duration = rental.plannedDurationHours;
          final plannedPrice =
              item == null || duration == null ? null : item.hourlyRate * duration;
          return DataRow(
            cells: [
              DataCell(Text(item?.name ?? rental.itemId)),
              DataCell(Text(customer?.name ?? rental.customerId)),
              DataCell(Text(duration == null
                  ? 'Nicht angegeben'
                  : '${_formatNumber(duration)} h')),
              DataCell(Text(plannedPrice == null
                  ? 'Wird bei Rückgabe berechnet'
                  : '${plannedPrice.toStringAsFixed(2)} €')),
              const DataCell(_StatusBadge(rented: true)),
              DataCell(
                TextButton.icon(
                  onPressed: () => onEnd(rental),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Beenden'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  RentalItem? _findItem(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Customer? _findCustomer(String id) {
    for (final customer in customers) {
      if (customer.id == id) return customer;
    }
    return null;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.rented});

  final bool rented;

  @override
  Widget build(BuildContext context) {
    final color = rented ? const Color(0xffd95d78) : const Color(0xff3a9d75);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        rented ? 'Ausgeliehen' : 'Verfügbar',
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xfff7fafb),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xff6d8290))),
    );
  }
}

class CustomerDialog extends StatefulWidget {
  const CustomerDialog({required this.api, super.key});

  final SkiApi api;

  @override
  State<CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<CustomerDialog> {
  final name = TextEditingController();
  final number = TextEditingController();
  String type = 'Personalausweis';
  String? fileName;
  Uint8List? fileBytes;
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    number.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        fileName = result.files.single.name;
        fileBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty || number.text.trim().isEmpty) return;
    setState(() => saving = true);
    try {
      final customer = await widget.api.createCustomer(
        name: name.text.trim(),
        documentType: type,
        documentNumber: number.text.trim(),
        fileName: fileName,
        fileBytes: fileBytes,
      );
      if (mounted) Navigator.pop(context, customer);
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(exception.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Person registrieren'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Ausweistyp'),
              items: ['Personalausweis', 'Reisepass']
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => type = value!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: number,
              decoration: const InputDecoration(labelText: 'Ausweisnummer'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(fileName ?? 'Ausweisdatei auswählen'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: saving ? null : _save,
          child: Text(saving ? 'Speichern...' : 'Speichern'),
        ),
      ],
    );
  }
}

class RentalDialog extends StatefulWidget {
  const RentalDialog({
    required this.api,
    required this.items,
    required this.customers,
    super.key,
  });

  final SkiApi api;
  final List<RentalItem> items;
  final List<Customer> customers;

  @override
  State<RentalDialog> createState() => _RentalDialogState();
}

class _RentalDialogState extends State<RentalDialog> {
  RentalItem? item;
  Customer? customer;
  final hours = TextEditingController(text: '1');
  bool saving = false;

  @override
  void dispose() {
    hours.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (item == null || customer == null) return;
    setState(() => saving = true);
    try {
      final rental = await widget.api.startRental(
        itemId: item!.id,
        customerId: customer!.id,
        startedAt: DateTime.now(),
        plannedDurationHours: double.tryParse(hours.text),
      );
      if (!mounted) return;
      Navigator.pop(context, rental);
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(exception.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.items.where((value) => !value.isRented).toList();
    return AlertDialog(
      title: const Text('Neue Ausleihe'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<RentalItem>(
              decoration: const InputDecoration(labelText: 'Verfügbarer Ski'),
              items: available
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                          '${value.name} · ${value.hourlyRate.toStringAsFixed(2)} € / h'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => item = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Customer>(
              decoration: const InputDecoration(labelText: 'Kunde'),
              items: widget.customers
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value.name)))
                  .toList(),
              onChanged: (value) => setState(() => customer = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hours,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Geplante Stunden',
                suffixText: 'h',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: saving ? null : _save,
          child: Text(saving ? 'Starten...' : 'Ausleihe starten'),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Color(0xffd95d78)),
            const SizedBox(height: 12),
            const Text(
              'Backend nicht erreichbar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: onRetry, child: const Text('Erneut versuchen')),
          ],
        ),
      ),
    );
  }
}
