import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

void main() {
  final OperationsStore store = kScreenshotMode
      ? MemoryOperationsStore.seeded()
      : SharedPrefsOperationsStore();
  runApp(TrouveMarinMichelApp(store: store));
}

class TrouveMarinMichelApp extends StatelessWidget {
  const TrouveMarinMichelApp({super.key, required this.store});

  final OperationsStore store;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF061733);
    const cyan = Color(0xFF007FE0);
    const blue = Color(0xFF000FE0);
    const steel = Color(0xFF667B96);

    final lightScheme = ColorScheme.fromSeed(
      seedColor: cyan,
      brightness: Brightness.light,
      primary: navy,
      secondary: cyan,
      tertiary: blue,
      surface: const Color(0xFFF5F8FC),
    );

    return MaterialApp(
      title: 'TROUVE MARIN MICHEL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: const Color(0xFFF5F8FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: steel.withAlpha(38)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: cyan.withAlpha(45),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? navy : steel,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
          titleMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0),
          bodyMedium: TextStyle(height: 1.35, letterSpacing: 0),
        ),
      ),
      home: OperationsShell(store: store),
    );
  }
}

abstract class OperationsStore {
  Future<OperationsSnapshot> load();
  Future<void> save(OperationsSnapshot snapshot);
}

class SharedPrefsOperationsStore implements OperationsStore {
  static const _storageKey = 'tmm_operations_snapshot_v1';

  @override
  Future<OperationsSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      return OperationsSnapshot.seeded();
    }
    return OperationsSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(OperationsSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(snapshot.toJson()));
  }
}

class MemoryOperationsStore implements OperationsStore {
  MemoryOperationsStore(this._snapshot);

  factory MemoryOperationsStore.seeded() =>
      MemoryOperationsStore(OperationsSnapshot.seeded());

  OperationsSnapshot _snapshot;

  @override
  Future<OperationsSnapshot> load() async => _snapshot;

  @override
  Future<void> save(OperationsSnapshot snapshot) async {
    _snapshot = snapshot;
  }
}

class OperationsSnapshot {
  const OperationsSnapshot({
    required this.tasks,
    required this.resources,
    required this.orders,
    required this.audits,
    required this.settings,
  });

  final List<OpsTask> tasks;
  final List<ResourceAllocation> resources;
  final List<SupplyOrder> orders;
  final List<AuditEvent> audits;
  final OperationsSettings settings;

  factory OperationsSnapshot.seeded() {
    final fixedMorning = DateTime(2026, 5, 12, 8, 10);
    return OperationsSnapshot(
      tasks: const [
        OpsTask(
          id: 'task-1',
          title: 'Verify cold room inventory',
          owner: 'Mina',
          area: 'Storage',
          dueLabel: 'Today 10:30',
          priority: 'High',
          status: 'In progress',
          notes:
              'Confirm receiving counts before the midday supply order is released.',
        ),
        OpsTask(
          id: 'task-2',
          title: 'Close morning safety walk',
          owner: 'Yanis',
          area: 'Floor team',
          dueLabel: 'Today 12:00',
          priority: 'Normal',
          status: 'Open',
          notes:
              'Attach checklist notes to the local audit log after the walk.',
        ),
        OpsTask(
          id: 'task-3',
          title: 'Resolve delayed packaging station',
          owner: 'Nora',
          area: 'Dispatch',
          dueLabel: 'Today 15:00',
          priority: 'High',
          status: 'Blocked',
          notes: 'Waiting for replacement labels from supply desk.',
        ),
      ],
      resources: const [
        ResourceAllocation(
          id: 'res-1',
          name: 'Dispatch team',
          owner: 'Nora',
          shift: '08:00 - 16:00',
          utilization: 82,
          status: 'Balanced',
        ),
        ResourceAllocation(
          id: 'res-2',
          name: 'Vehicle bay 2',
          owner: 'Samir',
          shift: '10:00 - 18:00',
          utilization: 64,
          status: 'Available',
        ),
        ResourceAllocation(
          id: 'res-3',
          name: 'Packing bench A',
          owner: 'Leila',
          shift: '12:00 - 20:00',
          utilization: 91,
          status: 'Tight',
        ),
      ],
      orders: const [
        SupplyOrder(
          id: 'order-1',
          item: 'Thermal label rolls',
          vendor: 'Local supply desk',
          quantity: '18 cartons',
          neededBy: 'Today',
          status: 'Pending approval',
        ),
        SupplyOrder(
          id: 'order-2',
          item: 'Blue security tape',
          vendor: 'Warehouse cabinet',
          quantity: '24 rolls',
          neededBy: 'Tomorrow',
          status: 'Ready',
        ),
      ],
      audits: [
        AuditEvent(
          id: 'audit-1',
          category: 'Task',
          message: 'Cold room inventory assigned to Mina',
          severity: 'Action',
          createdAt: fixedMorning,
        ),
        AuditEvent(
          id: 'audit-2',
          category: 'Supply',
          message: 'Thermal label rolls submitted for approval',
          severity: 'Review',
          createdAt: fixedMorning.subtract(const Duration(minutes: 28)),
        ),
        AuditEvent(
          id: 'audit-3',
          category: 'Resource',
          message: 'Packing bench A marked tight for the afternoon shift',
          severity: 'Watch',
          createdAt: fixedMorning.subtract(
            const Duration(hours: 1, minutes: 6),
          ),
        ),
      ],
      settings: const OperationsSettings(
        compactBoards: false,
        localReminder: true,
        supervisorName: 'Operations lead',
      ),
    );
  }

  factory OperationsSnapshot.fromJson(Map<String, dynamic> json) {
    return OperationsSnapshot(
      tasks: ((json['tasks'] as List<dynamic>?) ?? const [])
          .map((item) => OpsTask.fromJson(item as Map<String, dynamic>))
          .toList(),
      resources: ((json['resources'] as List<dynamic>?) ?? const [])
          .map(
            (item) => ResourceAllocation.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      orders: ((json['orders'] as List<dynamic>?) ?? const [])
          .map((item) => SupplyOrder.fromJson(item as Map<String, dynamic>))
          .toList(),
      audits: ((json['audits'] as List<dynamic>?) ?? const [])
          .map((item) => AuditEvent.fromJson(item as Map<String, dynamic>))
          .toList(),
      settings: OperationsSettings.fromJson(
        (json['settings'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'tasks': tasks.map((task) => task.toJson()).toList(),
    'resources': resources.map((resource) => resource.toJson()).toList(),
    'orders': orders.map((order) => order.toJson()).toList(),
    'audits': audits.map((audit) => audit.toJson()).toList(),
    'settings': settings.toJson(),
  };

  OperationsSnapshot copyWith({
    List<OpsTask>? tasks,
    List<ResourceAllocation>? resources,
    List<SupplyOrder>? orders,
    List<AuditEvent>? audits,
    OperationsSettings? settings,
  }) {
    return OperationsSnapshot(
      tasks: tasks ?? this.tasks,
      resources: resources ?? this.resources,
      orders: orders ?? this.orders,
      audits: audits ?? this.audits,
      settings: settings ?? this.settings,
    );
  }
}

class OpsTask {
  const OpsTask({
    required this.id,
    required this.title,
    required this.owner,
    required this.area,
    required this.dueLabel,
    required this.priority,
    required this.status,
    required this.notes,
  });

  final String id;
  final String title;
  final String owner;
  final String area;
  final String dueLabel;
  final String priority;
  final String status;
  final String notes;

  factory OpsTask.fromJson(Map<String, dynamic> json) => OpsTask(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    owner: json['owner'] as String? ?? '',
    area: json['area'] as String? ?? '',
    dueLabel: json['dueLabel'] as String? ?? '',
    priority: json['priority'] as String? ?? 'Normal',
    status: json['status'] as String? ?? 'Open',
    notes: json['notes'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'owner': owner,
    'area': area,
    'dueLabel': dueLabel,
    'priority': priority,
    'status': status,
    'notes': notes,
  };

  OpsTask copyWith({
    String? title,
    String? owner,
    String? area,
    String? dueLabel,
    String? priority,
    String? status,
    String? notes,
  }) {
    return OpsTask(
      id: id,
      title: title ?? this.title,
      owner: owner ?? this.owner,
      area: area ?? this.area,
      dueLabel: dueLabel ?? this.dueLabel,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

class ResourceAllocation {
  const ResourceAllocation({
    required this.id,
    required this.name,
    required this.owner,
    required this.shift,
    required this.utilization,
    required this.status,
  });

  final String id;
  final String name;
  final String owner;
  final String shift;
  final int utilization;
  final String status;

  factory ResourceAllocation.fromJson(Map<String, dynamic> json) =>
      ResourceAllocation(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        owner: json['owner'] as String? ?? '',
        shift: json['shift'] as String? ?? '',
        utilization: json['utilization'] as int? ?? 0,
        status: json['status'] as String? ?? 'Available',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'owner': owner,
    'shift': shift,
    'utilization': utilization,
    'status': status,
  };
}

class SupplyOrder {
  const SupplyOrder({
    required this.id,
    required this.item,
    required this.vendor,
    required this.quantity,
    required this.neededBy,
    required this.status,
  });

  final String id;
  final String item;
  final String vendor;
  final String quantity;
  final String neededBy;
  final String status;

  factory SupplyOrder.fromJson(Map<String, dynamic> json) => SupplyOrder(
    id: json['id'] as String? ?? '',
    item: json['item'] as String? ?? '',
    vendor: json['vendor'] as String? ?? '',
    quantity: json['quantity'] as String? ?? '',
    neededBy: json['neededBy'] as String? ?? '',
    status: json['status'] as String? ?? 'Draft',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'item': item,
    'vendor': vendor,
    'quantity': quantity,
    'neededBy': neededBy,
    'status': status,
  };
}

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.category,
    required this.message,
    required this.severity,
    required this.createdAt,
  });

  final String id;
  final String category;
  final String message;
  final String severity;
  final DateTime createdAt;

  factory AuditEvent.create({
    required String category,
    required String message,
    required String severity,
  }) {
    final now = DateTime.now();
    return AuditEvent(
      id: 'audit-${now.microsecondsSinceEpoch}',
      category: category,
      message: message,
      severity: severity,
      createdAt: now,
    );
  }

  factory AuditEvent.fromJson(Map<String, dynamic> json) => AuditEvent(
    id: json['id'] as String? ?? '',
    category: json['category'] as String? ?? 'General',
    message: json['message'] as String? ?? '',
    severity: json['severity'] as String? ?? 'Info',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'message': message,
    'severity': severity,
    'createdAt': createdAt.toIso8601String(),
  };
}

class OperationsSettings {
  const OperationsSettings({
    required this.compactBoards,
    required this.localReminder,
    required this.supervisorName,
  });

  final bool compactBoards;
  final bool localReminder;
  final String supervisorName;

  factory OperationsSettings.fromJson(Map<String, dynamic> json) =>
      OperationsSettings(
        compactBoards: json['compactBoards'] as bool? ?? false,
        localReminder: json['localReminder'] as bool? ?? true,
        supervisorName: json['supervisorName'] as String? ?? 'Operations lead',
      );

  Map<String, dynamic> toJson() => {
    'compactBoards': compactBoards,
    'localReminder': localReminder,
    'supervisorName': supervisorName,
  };

  OperationsSettings copyWith({
    bool? compactBoards,
    bool? localReminder,
    String? supervisorName,
  }) {
    return OperationsSettings(
      compactBoards: compactBoards ?? this.compactBoards,
      localReminder: localReminder ?? this.localReminder,
      supervisorName: supervisorName ?? this.supervisorName,
    );
  }
}

class OperationsShell extends StatefulWidget {
  const OperationsShell({super.key, required this.store});

  final OperationsStore store;

  @override
  State<OperationsShell> createState() => _OperationsShellState();
}

class _OperationsShellState extends State<OperationsShell> {
  OperationsSnapshot? _snapshot;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await widget.store.load();
    if (!mounted) {
      return;
    }
    setState(() => _snapshot = loaded);
  }

  Future<void> _commit(OperationsSnapshot snapshot) async {
    setState(() => _snapshot = snapshot);
    await widget.store.save(snapshot);
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _addTask(OpsTask task) async {
    final current = _snapshot!;
    await _commit(
      current.copyWith(
        tasks: [task, ...current.tasks],
        audits: [
          AuditEvent.create(
            category: 'Task',
            message: '${task.title} assigned to ${task.owner}',
            severity: task.priority == 'High' ? 'Action' : 'Info',
          ),
          ...current.audits,
        ],
      ),
    );
  }

  Future<void> _updateTask(OpsTask task, String status) async {
    final current = _snapshot!;
    await _commit(
      current.copyWith(
        tasks: [
          for (final item in current.tasks)
            item.id == task.id ? task.copyWith(status: status) : item,
        ],
        audits: [
          AuditEvent.create(
            category: 'Task',
            message: '${task.title} moved to $status',
            severity: status == 'Blocked' ? 'Watch' : 'Info',
          ),
          ...current.audits,
        ],
      ),
    );
  }

  Future<void> _addResource(ResourceAllocation resource) async {
    final current = _snapshot!;
    await _commit(
      current.copyWith(
        resources: [resource, ...current.resources],
        audits: [
          AuditEvent.create(
            category: 'Resource',
            message: '${resource.name} allocated to ${resource.owner}',
            severity: resource.utilization > 85 ? 'Watch' : 'Info',
          ),
          ...current.audits,
        ],
      ),
    );
  }

  Future<void> _addOrder(SupplyOrder order) async {
    final current = _snapshot!;
    await _commit(
      current.copyWith(
        orders: [order, ...current.orders],
        audits: [
          AuditEvent.create(
            category: 'Supply',
            message: '${order.item} order logged for ${order.neededBy}',
            severity: order.status == 'Pending approval' ? 'Review' : 'Info',
          ),
          ...current.audits,
        ],
      ),
    );
  }

  Future<void> _updateSettings(OperationsSettings settings) async {
    final current = _snapshot!;
    await _commit(
      current.copyWith(
        settings: settings,
        audits: [
          AuditEvent.create(
            category: 'Settings',
            message: 'Local operations preferences updated',
            severity: 'Info',
          ),
          ...current.audits,
        ],
      ),
    );
  }

  Future<void> _openCreateSheet() async {
    if (_snapshot == null) {
      return;
    }
    if (_selectedIndex == 1) {
      final task = await showModalBottomSheet<OpsTask>(
        context: context,
        isScrollControlled: true,
        builder: (context) => const _TaskForm(),
      );
      if (task != null) {
        await _addTask(task);
      }
    } else if (_selectedIndex == 2) {
      final resource = await showModalBottomSheet<ResourceAllocation>(
        context: context,
        isScrollControlled: true,
        builder: (context) => const _ResourceForm(),
      );
      if (resource != null) {
        await _addResource(resource);
      }
    } else if (_selectedIndex == 3) {
      final order = await showModalBottomSheet<SupplyOrder>(
        context: context,
        isScrollControlled: true,
        builder: (context) => const _OrderForm(),
      );
      if (order != null) {
        await _addOrder(order);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      DashboardScreen(
        snapshot: snapshot,
        onOpenTasks: () => _selectTab(1),
        onOpenResources: () => _selectTab(2),
        onOpenOrders: () => _selectTab(3),
      ),
      TasksScreen(
        tasks: snapshot.tasks,
        compact: snapshot.settings.compactBoards,
        onTaskStatusChanged: _updateTask,
      ),
      ResourcesScreen(resources: snapshot.resources),
      OrdersScreen(orders: snapshot.orders),
      AuditScreen(audits: snapshot.audits),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TROUVE MARIN MICHEL'),
        actions: [
          IconButton(
            tooltip: 'Settings and privacy',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => SettingsScreen(
                    settings: snapshot.settings,
                    onChanged: _updateSettings,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      floatingActionButton: _selectedIndex >= 1 && _selectedIndex <= 3
          ? FloatingActionButton.extended(
              tooltip: _selectedIndex == 1
                  ? 'Add task'
                  : _selectedIndex == 2
                  ? 'Add resource'
                  : 'Add supply order',
              onPressed: _openCreateSheet,
              icon: const Icon(Icons.add),
              label: Text(
                _selectedIndex == 1
                    ? 'Task'
                    : _selectedIndex == 2
                    ? 'Resource'
                    : 'Order',
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            key: ValueKey('nav-dashboard'),
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            key: ValueKey('nav-tasks'),
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Tasks',
          ),
          NavigationDestination(
            key: ValueKey('nav-resources'),
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Resources',
          ),
          NavigationDestination(
            key: ValueKey('nav-orders'),
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Orders',
          ),
          NavigationDestination(
            key: ValueKey('nav-audit'),
            icon: Icon(Icons.manage_search_outlined),
            selectedIcon: Icon(Icons.manage_search),
            label: 'Audit',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.snapshot,
    required this.onOpenTasks,
    required this.onOpenResources,
    required this.onOpenOrders,
  });

  final OperationsSnapshot snapshot;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenResources;
  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) {
    final openTasks = snapshot.tasks
        .where((task) => task.status != 'Done')
        .length;
    final blockedTasks = snapshot.tasks
        .where((task) => task.status == 'Blocked')
        .length;
    final pendingOrders = snapshot.orders
        .where((order) => order.status != 'Ready')
        .length;
    final utilization = snapshot.resources.isEmpty
        ? 0
        : (snapshot.resources
                      .map((item) => item.utilization)
                      .reduce((a, b) => a + b) /
                  snapshot.resources.length)
              .round();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _HeroPanel(openTasks: openTasks, utilization: utilization),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(
                label: 'Open tasks',
                value: '$openTasks',
                icon: Icons.fact_check,
              ),
              _MetricTile(
                label: 'Blocked',
                value: '$blockedTasks',
                icon: Icons.report_problem,
              ),
              _MetricTile(
                label: 'Allocation',
                value: '$utilization%',
                icon: Icons.groups,
              ),
              _MetricTile(
                label: 'Supply queue',
                value: '$pendingOrders',
                icon: Icons.inventory,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Today in control',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.fact_check_outlined,
            title: 'Task management',
            body:
                'Review owners, due windows, and blocked items before the next handoff.',
            actionLabel: 'Open tasks',
            onPressed: onOpenTasks,
          ),
          _ActionCard(
            icon: Icons.groups_outlined,
            title: 'Resource allocation',
            body:
                'Track utilization for people, stations, and vehicles in each shift.',
            actionLabel: 'Open resources',
            onPressed: onOpenResources,
          ),
          _ActionCard(
            icon: Icons.inventory_2_outlined,
            title: 'Supply ordering',
            body:
                'Keep orders tied to operational needs without sending data off device.',
            actionLabel: 'Open orders',
            onPressed: onOpenOrders,
          ),
          const SizedBox(height: 8),
          Text(
            'Latest audit entries',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...snapshot.audits
              .take(3)
              .map((event) => AuditListTile(event: event)),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.openTasks, required this.utilization});

  final int openTasks;
  final int utilization;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF061733);
    const cyan = Color(0xFF16CAD3);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cyan.withAlpha(42),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_outlined, color: cyan),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Operations command center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$openTasks active tasks, $utilization% average resource use',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Log work, allocate resources, and prepare supply requests in one local workspace.',
            style: TextStyle(color: Color(0xFFDDEBFF), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 42) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.tertiary),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(body),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: onPressed,
                      child: Text(actionLabel),
                    ),
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

class TasksScreen extends StatelessWidget {
  const TasksScreen({
    super.key,
    required this.tasks,
    required this.compact,
    required this.onTaskStatusChanged,
  });

  final List<OpsTask> tasks;
  final bool compact;
  final Future<void> Function(OpsTask task, String status) onTaskStatusChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _ScreenHeader(
              title: 'Task management',
              subtitle:
                  'Assign owners, due windows, and completion status for daily work.',
              icon: Icons.fact_check,
            );
          }
          final task = tasks[index - 1];
          return TaskCard(
            task: task,
            compact: compact,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => TaskDetailScreen(
                    task: task,
                    onStatusChanged: onTaskStatusChanged,
                  ),
                ),
              );
            },
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemCount: tasks.length + 1,
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.compact,
    required this.onTap,
  });

  final OpsTask task;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _StatusChip(label: task.status),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(icon: Icons.person_outline, label: task.owner),
                  _InfoChip(icon: Icons.place_outlined, label: task.area),
                  _InfoChip(icon: Icons.schedule, label: task.dueLabel),
                  _InfoChip(icon: Icons.flag_outlined, label: task.priority),
                ],
              ),
              if (!compact) ...[const SizedBox(height: 10), Text(task.notes)],
            ],
          ),
        ),
      ),
    );
  }
}

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.onStatusChanged,
  });

  final OpsTask task;
  final Future<void> Function(OpsTask task, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task detail')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              task.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(label: task.status),
                _InfoChip(icon: Icons.person_outline, label: task.owner),
                _InfoChip(icon: Icons.place_outlined, label: task.area),
                _InfoChip(icon: Icons.schedule, label: task.dueLabel),
              ],
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  task.notes,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Update status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonal(
                  onPressed: () async {
                    await onStatusChanged(task, 'In progress');
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('In progress'),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    await onStatusChanged(task, 'Blocked');
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Blocked'),
                ),
                FilledButton(
                  onPressed: () async {
                    await onStatusChanged(task, 'Done');
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Mark done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key, required this.resources});

  final List<ResourceAllocation> resources;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _ScreenHeader(
              title: 'Resource allocation',
              subtitle:
                  'Keep teams, workstations, and equipment aligned to today shifts.',
              icon: Icons.groups,
            );
          }
          final resource = resources[index - 1];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          resource.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      _StatusChip(label: resource.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: resource.utilization / 100),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.person_outline,
                        label: resource.owner,
                      ),
                      _InfoChip(icon: Icons.access_time, label: resource.shift),
                      _InfoChip(
                        icon: Icons.speed,
                        label: '${resource.utilization}% used',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemCount: resources.length + 1,
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, required this.orders});

  final List<SupplyOrder> orders;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _ScreenHeader(
              title: 'Supply ordering',
              subtitle:
                  'Prepare order requests and keep supplies tied to daily operation needs.',
              icon: Icons.inventory_2,
            );
          }
          final order = orders[index - 1];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.item,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      _StatusChip(label: order.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.storefront_outlined,
                        label: order.vendor,
                      ),
                      _InfoChip(
                        icon: Icons.inventory_outlined,
                        label: order.quantity,
                      ),
                      _InfoChip(
                        icon: Icons.event_available_outlined,
                        label: order.neededBy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemCount: orders.length + 1,
      ),
    );
  }
}

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key, required this.audits});

  final List<AuditEvent> audits;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _ScreenHeader(
              title: 'Audit logs',
              subtitle:
                  'Every local task, resource, supply, and preference change is listed here.',
              icon: Icons.manage_search,
            );
          }
          return AuditListTile(event: audits[index - 1]);
        },
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemCount: audits.length + 1,
      ),
    );
  }
}

class AuditListTile extends StatelessWidget {
  const AuditListTile({super.key, required this.event});

  final AuditEvent event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.secondary.withAlpha(35),
              child: Icon(
                Icons.done_all,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.message,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      _StatusChip(label: event.severity),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${event.category} - ${_formatAuditTime(event.createdAt)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final OperationsSettings settings;
  final Future<void> Function(OperationsSettings settings) onChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late OperationsSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  Future<void> _save(OperationsSettings settings) async {
    setState(() => _settings = settings);
    await widget.onChanged(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings and privacy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _ScreenHeader(
              title: 'Local workspace',
              subtitle:
                  'Preferences and records stay on this device. The app has no account login or cloud sync.',
              icon: Icons.admin_panel_settings,
            ),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Compact boards'),
                    subtitle: const Text(
                      'Show shorter task cards during busy reviews.',
                    ),
                    value: _settings.compactBoards,
                    onChanged: (value) =>
                        _save(_settings.copyWith(compactBoards: value)),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Local reminder flag'),
                    subtitle: const Text(
                      'Keep reminder preference available for daily handoff checks.',
                    ),
                    value: _settings.localReminder,
                    onChanged: (value) =>
                        _save(_settings.copyWith(localReminder: value)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy posture',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'TROUVE MARIN MICHEL stores operation records and preferences locally on the device. It does not require account registration, analytics, advertising identifiers, location, contacts, camera, microphone, or network access.',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Support',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text('support@trouvemarinmichel.com'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withAlpha(36),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.tertiary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Blocked' || 'Watch' || 'Tight' => const Color(0xFFB64710),
      'Done' || 'Ready' || 'Balanced' || 'Available' => const Color(0xFF087A59),
      'High' ||
      'Action' ||
      'Pending approval' ||
      'Review' => Theme.of(context).colorScheme.tertiary,
      _ => Theme.of(context).colorScheme.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Theme.of(context).colorScheme.tertiary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskForm extends StatefulWidget {
  const _TaskForm();

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _ownerController = TextEditingController();
  final _areaController = TextEditingController(text: 'Operations');
  final _dueController = TextEditingController(text: 'Today');
  final _notesController = TextEditingController(
    text: 'Add notes for the next handoff.',
  );
  String _priority = 'Normal';

  @override
  void dispose() {
    _titleController.dispose();
    _ownerController.dispose();
    _areaController.dispose();
    _dueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: 'Add task',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('task-title-field'),
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task title'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const ValueKey('task-owner-field'),
              controller: _ownerController,
              decoration: const InputDecoration(labelText: 'Owner'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(labelText: 'Area'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _dueController,
              decoration: const InputDecoration(labelText: 'Due window'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                DropdownMenuItem(value: 'High', child: Text('High')),
              ],
              onChanged: (value) =>
                  setState(() => _priority = value ?? 'Normal'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  final now = DateTime.now().microsecondsSinceEpoch;
                  Navigator.of(context).pop(
                    OpsTask(
                      id: 'task-$now',
                      title: _titleController.text.trim(),
                      owner: _ownerController.text.trim(),
                      area: _areaController.text.trim(),
                      dueLabel: _dueController.text.trim(),
                      priority: _priority,
                      status: 'Open',
                      notes: _notesController.text.trim(),
                    ),
                  );
                },
                child: const Text('Save task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceForm extends StatefulWidget {
  const _ResourceForm();

  @override
  State<_ResourceForm> createState() => _ResourceFormState();
}

class _ResourceFormState extends State<_ResourceForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _shiftController = TextEditingController(text: 'Today');
  double _utilization = 70;

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _shiftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: 'Add resource',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Resource'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _ownerController,
              decoration: const InputDecoration(labelText: 'Owner'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _shiftController,
              decoration: const InputDecoration(labelText: 'Shift'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _utilization,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (value) => setState(() => _utilization = value),
                  ),
                ),
                SizedBox(width: 52, child: Text('${_utilization.round()}%')),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  final utilization = _utilization.round();
                  Navigator.of(context).pop(
                    ResourceAllocation(
                      id: 'res-${DateTime.now().microsecondsSinceEpoch}',
                      name: _nameController.text.trim(),
                      owner: _ownerController.text.trim(),
                      shift: _shiftController.text.trim(),
                      utilization: utilization,
                      status: utilization > 85 ? 'Tight' : 'Available',
                    ),
                  );
                },
                child: const Text('Save resource'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderForm extends StatefulWidget {
  const _OrderForm();

  @override
  State<_OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<_OrderForm> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _vendorController = TextEditingController(text: 'Preferred supplier');
  final _quantityController = TextEditingController(text: '1 case');
  final _neededByController = TextEditingController(text: 'Today');
  String _status = 'Pending approval';

  @override
  void dispose() {
    _itemController.dispose();
    _vendorController.dispose();
    _quantityController.dispose();
    _neededByController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: 'Add supply order',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _itemController,
              decoration: const InputDecoration(labelText: 'Item'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _vendorController,
              decoration: const InputDecoration(labelText: 'Vendor or source'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _neededByController,
              decoration: const InputDecoration(labelText: 'Needed by'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(
                  value: 'Pending approval',
                  child: Text('Pending approval'),
                ),
                DropdownMenuItem(value: 'Ready', child: Text('Ready')),
              ],
              onChanged: (value) =>
                  setState(() => _status = value ?? 'Pending approval'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  Navigator.of(context).pop(
                    SupplyOrder(
                      id: 'order-${DateTime.now().microsecondsSinceEpoch}',
                      item: _itemController.text.trim(),
                      vendor: _vendorController.text.trim(),
                      quantity: _quantityController.text.trim(),
                      neededBy: _neededByController.text.trim(),
                      status: _status,
                    ),
                  );
                },
                child: const Text('Save order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormShell extends StatelessWidget {
  const _FormShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  return null;
}

String _formatAuditTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
