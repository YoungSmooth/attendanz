import 'section_adjuster.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOJ Attendanz',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// HomeScreen: Welcome, logo, Create Attendance button, FAB
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Attendance> savedAttendances = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAttendances();
  }

  Future<void> loadAttendances() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('attendances') ?? [];
    setState(() {
      savedAttendances = list
          .map((e) => Attendance.fromJson(jsonDecode(e)))
          .toList();
      loading = false;
    });
  }

  Future<void> _deleteAttendance(String id) async {
    final prefs = await SharedPreferences.getInstance();
    savedAttendances.removeWhere((a) => a.id == id);
    await prefs.setStringList(
      'attendances',
      savedAttendances.map((a) => jsonEncode(a.toJson())).toList(),
    );
    setState(() {});
  }

  void _showDeleteConfirm(BuildContext context, Attendance att) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(CupertinoIcons.trash, color: Colors.red, size: 40),
                const SizedBox(height: 16),
                Text(
                  'Delete "${att.name}"?',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'This attendance and all its data will be permanently deleted.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: Colors.grey[200],
                        child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: const Text('Delete'),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _deleteAttendance(att.id);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAttendance(Attendance att) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AttendanceDetailScreen(attendance: att, onSave: loadAttendances),
      ),
    );
    // Always reload attendances after returning from detail screen
    await loadAttendances();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onSecondary,
      appBar: AppBar(
        title: const Text(
          'SOJ Attendanz',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.onSecondary,
      ),
      body: savedAttendances.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.how_to_reg,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome to SOJ Attendanz',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 220,
                    child: CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(14),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: () {
                        _showCreateAttendanceModal(context);
                      },
                      child: const Text('Create Attendance', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: loadAttendances,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: savedAttendances.length,
                itemBuilder: (context, i) {
                  final att = savedAttendances[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(att.name),
                      subtitle: Row(
                        children: [
                          _CounterPill(
                            label: 'Total',
                            count: att.totalPresent,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _CounterPill(
                            label: 'Male',
                            count: att.totalMale,
                            color: Colors.lightBlue,
                          ),
                          const SizedBox(width: 8),
                          _CounterPill(
                            label: 'Female',
                            count: att.totalFemale,
                            color: Colors.pinkAccent,
                          ),
                        ],
                      ),
                      onTap: () => _openAttendance(att),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirm(context, att);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: savedAttendances.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () {
                _showCreateAttendanceModal(context);
              },
              tooltip: 'Create Attendance',
              child: const Icon(Icons.edit),
            ),
    );
  }
}

  void _showCreateAttendanceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 32,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: _CreateAttendanceSheet(onCreate: (attendance) async {
            await (context.findAncestorStateOfType<_HomeScreenState>()?.loadAttendances() ?? Future.value());
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AttendanceDetailScreen(
                  attendance: attendance,
                  onSave: context.findAncestorStateOfType<_HomeScreenState>()?.loadAttendances,
                ),
              ),
            );
          }),
        );
      },
    );
  }

// Apple-style bottom sheet for creating attendance
class _CreateAttendanceSheet extends StatefulWidget {
  final void Function(Attendance) onCreate;
  const _CreateAttendanceSheet({required this.onCreate});

  @override
  State<_CreateAttendanceSheet> createState() => _CreateAttendanceSheetState();
}

class _CreateAttendanceSheetState extends State<_CreateAttendanceSheet> {
  final TextEditingController _nameController = TextEditingController();
  int _sectionCount = 1;
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: bottom > 0 ? bottom : 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'New Attendance',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              CupertinoTextField(
                controller: _nameController,
                placeholder: 'Attendance Name',
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                style: const TextStyle(fontSize: 18),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Section Count', style: TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.all(0),
                        minSize: 36,
                        child: const Icon(CupertinoIcons.minus_circle, size: 32),
                        onPressed: _sectionCount > 1 && !_creating ? () => setState(() => _sectionCount--) : null,
                      ),
                      Container(
                        width: 36,
                        alignment: Alignment.center,
                        child: Text('$_sectionCount', style: const TextStyle(fontSize: 20)),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.all(0),
                        minSize: 36,
                        child: const Icon(CupertinoIcons.add_circled, size: 32),
                        onPressed: _sectionCount < 10 && !_creating ? () => setState(() => _sectionCount++) : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: Colors.grey[200],
                      child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: _creating ? const CupertinoActivityIndicator() : const Text('Create'),
                      onPressed: _creating
                          ? null
                          : () async {
                              if (_nameController.text.trim().isEmpty) return;
                              setState(() => _creating = true);
                              final uuid = Uuid();
                              final attendance = Attendance(
                                id: uuid.v4(),
                                name: _nameController.text.trim(),
                                createdAt: DateTime.now(),
                                sections: List.generate(_sectionCount, (i) {
                                  return Section(
                                    id: uuid.v4(),
                                    label: String.fromCharCode(65 + i),
                                  );
                                }),
                              );
                              final prefs = await SharedPreferences.getInstance();
                              final list = prefs.getStringList('attendances') ?? [];
                              list.add(jsonEncode(attendance.toJson()));
                              await prefs.setStringList('attendances', list);
                              widget.onCreate(attendance);
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// Update Attendance model for JSON serialization
class Attendance {
  final String id;
  String name;
  final DateTime createdAt;
  List<Section> sections;
  int totalPresent;
  int totalMale;
  int totalFemale;

  Attendance({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.sections,
    this.totalPresent = 0,
    this.totalMale = 0,
    this.totalFemale = 0,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      sections: (json['sections'] as List)
          .map((e) => Section.fromJson(e))
          .toList(),
      totalPresent: json['totalPresent'] ?? 0,
      totalMale: json['totalMale'] ?? 0,
      totalFemale: json['totalFemale'] ?? 0,
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'sections': sections.map((e) => e.toJson()).toList(),
    'totalPresent': totalPresent,
    'totalMale': totalMale,
    'totalFemale': totalFemale,
  };
}

class Section {
  final String id;
  String label;
  int rows;
  int cols;
  List<List<Cell>> cells;

  Section({required this.id, required this.label, this.rows = 5, this.cols = 5})
    : cells = List.generate(5, (_) => List.generate(5, (_) => Cell()));

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
        id: json['id'],
        label: json['label'],
        rows: json['rows'],
        cols: json['cols'],
      )
      ..cells = (json['cells'] as List)
          .map(
            (row) => (row as List).map((cell) => Cell.fromJson(cell)).toList(),
          )
          .toList();
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'rows': rows,
    'cols': cols,
    'cells': cells
        .map((row) => row.map((cell) => cell.toJson()).toList())
        .toList(),
  };

  int get presentCount =>
      cells.expand((row) => row).where((c) => c.present).length;
  int get maleCount => cells
      .expand((row) => row)
      .where((c) => c.present && c.gender == 'male')
      .length;
  int get femaleCount => cells
      .expand((row) => row)
      .where((c) => c.present && c.gender == 'female')
      .length;
}

class Cell {
  bool present;
  String? gender; // 'male', 'female', or null
  String? name;
  Cell({this.present = false, this.gender, this.name});

  factory Cell.fromJson(Map<String, dynamic> json) {
    return Cell(
      present: json['present'],
      gender: json['gender'],
      name: json['name'],
    );
  }
  Map<String, dynamic> toJson() => {
    'present': present,
    'gender': gender,
    'name': name,
  };
}

// Attendance Detail Screen with section grid and save FAB
class AttendanceDetailScreen extends StatefulWidget {
  final Attendance attendance;
  final Future<void> Function()? onSave;
  const AttendanceDetailScreen({
    super.key,
    required this.attendance,
    this.onSave,
  });

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  late Attendance attendance;

  @override
  void initState() {
    super.initState();
    attendance = widget.attendance;
  }

  Future<void> _saveAttendance() async {
    // Calculate totals before saving
    int totalPresent = 0;
    int totalMale = 0;
    int totalFemale = 0;
    for (final section in attendance.sections) {
      for (final row in section.cells) {
        for (final cell in row) {
          if (cell.present) {
            totalPresent++;
            if (cell.gender == 'male') totalMale++;
            if (cell.gender == 'female') totalFemale++;
          }
        }
      }
    }
    attendance.totalPresent = totalPresent;
    attendance.totalMale = totalMale;
    attendance.totalFemale = totalFemale;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('attendances') ?? [];
    final idx = list.indexWhere(
      (e) => Attendance.fromJson(jsonDecode(e)).id == attendance.id,
    );
    if (idx != -1) {
      list[idx] = jsonEncode(attendance.toJson());
    } else {
      list.add(jsonEncode(attendance.toJson()));
    }
    await prefs.setStringList('attendances', list);
    if (widget.onSave != null) await widget.onSave!();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Attendance saved.')));
    }
  }

  void _renameSection(int sectionIdx) async {
    final controller = TextEditingController(
      text: attendance.sections[sectionIdx].label,
    );
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Section'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Section Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      setState(() {
        attendance.sections[sectionIdx].label = newName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPresent = 0;
    int totalMale = 0;
    int totalFemale = 0;
    for (final section in attendance.sections) {
      for (final row in section.cells) {
        for (final cell in row) {
          if (cell.present) {
            totalPresent++;
            if (cell.gender == 'male') totalMale++;
            if (cell.gender == 'female') totalFemale++;
          }
        }
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(attendance.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CounterPill(
                  label: 'Total',
                  count: totalPresent,
                  color: Colors.blue,
                ),
                _CounterPill(
                  label: 'Male',
                  count: totalMale,
                  color: Colors.lightBlue,
                ),
                _CounterPill(
                  label: 'Female',
                  count: totalFemale,
                  color: Colors.pinkAccent,
                ),
              ],
            ),
          ),
          Expanded(
            child: attendance.sections.isEmpty
                ? const Center(child: Text('No sections'))
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: List.generate(attendance.sections.length, (i) {
                      final section = attendance.sections[i];
                      return SizedBox(
                        width: 350,
                        child: SectionPanel(
                          section: section,
                          onSectionChanged: (updatedSection) {
                            setState(() {
                              attendance.sections[i] = updatedSection;
                            });
                          },
                          onRename: () => _renameSection(i),
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveAttendance,
        tooltip: 'Save Attendance',
        child: const Icon(Icons.save),
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CounterPill({
    required this.label,
    required this.count,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            '$count',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class SectionPanel extends StatefulWidget {
  final Section section;
  final ValueChanged<Section> onSectionChanged;
  final VoidCallback? onRename;
  const SectionPanel({
    super.key,
    required this.section,
    required this.onSectionChanged,
    this.onRename,
  });

  @override
  State<SectionPanel> createState() => _SectionPanelState();
}

class _SectionPanelState extends State<SectionPanel> {
  late Section section;

  @override
  void initState() {
    super.initState();
    section = widget.section;
  }

  void _changeRows(int delta) {
    setState(() {
      int newRows = section.rows + delta;
      if (newRows >= 1 && newRows <= 20) {
        section.rows = newRows;
        if (delta > 0) {
          section.cells.add(List.generate(section.cols, (_) => Cell()));
        } else {
          section.cells.removeLast();
        }
      }
    });
    widget.onSectionChanged(section);
  }

  void _changeCols(int delta) {
    setState(() {
      int newCols = section.cols + delta;
      if (newCols >= 1 && newCols <= 20) {
        section.cols = newCols;
        for (var row in section.cells) {
          if (delta > 0) {
            row.add(Cell());
          } else {
            row.removeLast();
          }
        }
      }
    });
    widget.onSectionChanged(section);
  }

  void _toggleCell(int row, int col) async {
    setState(() {
      section.cells[row][col].present = !section.cells[row][col].present;
      if (!section.cells[row][col].present) {
        section.cells[row][col].gender = null;
      }
    });
    if (section.cells[row][col].present &&
        section.cells[row][col].gender == null) {
      String? gender = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Select Gender'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'male'),
              child: const Text('Male'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'female'),
              child: const Text('Female'),
            ),
          ],
        ),
      );
      setState(() {
        section.cells[row][col].gender = gender;
      });
    }
    widget.onSectionChanged(section);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onRename,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.deepPurple.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          section.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Colors.deepPurple.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SectionAdjuster(
                  label: 'Rows',
                  value: section.rows,
                  onAdd: section.rows < 20 ? () => _changeRows(1) : null,
                  onRemove: section.rows > 1 ? () => _changeRows(-1) : null,
                ),
                const SizedBox(width: 10),
                SectionAdjuster(
                  label: 'Cols',
                  value: section.cols,
                  onAdd: section.cols < 20 ? () => _changeCols(1) : null,
                  onRemove: section.cols > 1 ? () => _changeCols(-1) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: List.generate(section.rows, (row) {
                    return Row(
                      children: List.generate(section.cols, (col) {
                        final cell = section.cells[row][col];
                        Color fillColor;
                        if (!cell.present) {
                          fillColor = Colors.grey[200]!;
                        } else if (cell.gender == 'male') {
                          fillColor = Colors.blue.shade300;
                        } else if (cell.gender == 'female') {
                          fillColor = Colors.pink.shade200;
                        } else {
                          fillColor = Colors.deepPurple.shade200;
                        }
                        return GestureDetector(
                          onTap: () => _toggleCell(row, col),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.all(4),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: fillColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.deepPurple.shade100,
                                width: 1.2,
                              ),
                              boxShadow: cell.present
                                  ? [
                                      BoxShadow(
                                        color: fillColor.withOpacity(0.18),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
