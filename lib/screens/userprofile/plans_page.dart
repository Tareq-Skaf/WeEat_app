import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/session.dart';

class PlanItem {
  final String id;
  final String title;
  final String restaurantId;
  final String restaurantName;
  final String restaurantAddress;
  final String date;
  final String time;
  final String notes;

  PlanItem({
    required this.id,
    required this.title,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.date,
    required this.time,
    required this.notes,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    return PlanItem(
      id: (json["id"] ?? "").toString(),
      title: (json["title"] ?? "Plan").toString(),
      restaurantId: (json["restaurant_id"] ?? "").toString(),
      restaurantName: (json["restaurant_name"] ?? "").toString(),
      restaurantAddress: (json["restaurant_address"] ?? "").toString(),
      date: (json["date"] ?? "").toString(),
      time: (json["time"] ?? "").toString(),
      notes: (json["notes"] ?? "").toString(),
    );
  }
}

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  static const Color background = Color(0xFFFEF9EE);
  static const Color planYellow = Color(0xFFFFD700);
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accent = Color(0xFF6F8574);

  final ApiService _api = ApiService();

  DateTime selectedDate = DateTime.now();
  int currentMonth = DateTime.now().month;
  int currentYear = DateTime.now().year;

  bool _loading = true;
  String? _error;
  List<PlanItem> _plans = [];

  @override
  void initState() {
    super.initState();
    currentMonth = DateTime.now().month;
    currentYear = DateTime.now().year;
    selectedDate = DateTime.now();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final email = Session.email.trim();

    if (email.isEmpty) {
      setState(() {
        _loading = false;
        _error = "You are not logged in.";
        _plans = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.getPlans(email: email);
      final list = data.map((e) => PlanItem.fromJson(Map<String, dynamic>.from(e))).toList();

      if (!mounted) return;
      setState(() {
        _plans = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _loading = false;
        _plans = [];
      });
    }
  }

  final List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> dayNames = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  int getDaysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

  int getFirstDayOfMonth(int month, int year) {
    return DateTime(year, month, 1).weekday % 7;
  }

  void previousMonth() {
    setState(() {
      if (currentMonth == 1) {
        currentMonth = 12;
        currentYear--;
      } else {
        currentMonth--;
      }
    });
  }

  void nextMonth() {
    setState(() {
      if (currentMonth == 12) {
        currentMonth = 1;
        currentYear++;
      } else {
        currentMonth++;
      }
    });
  }

  List<PlanItem> get _plansForSelectedDate {
    final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    return _plans.where((p) => p.date == dateStr).toList();
  }

  void _showCreatePlanDialog() {
    String title = "";
    String restaurantName = "";
    String time = "19:00";
    String notes = "";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Create Plan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Event Title',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) => title = value,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: "e.g., Brunch with friends",
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Restaurant (optional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) => restaurantName = value,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: "e.g., Pickl",
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Time',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) => time = value,
                    controller: TextEditingController(text: time),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: "e.g., 19:00",
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Notes (optional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) => notes = value,
                    maxLines: 2,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: "Any additional notes...",
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                onPressed: () async {
                  if (title.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a title")),
                    );
                    return;
                  }

                  Navigator.pop(context);

                  final email = Session.email.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not logged in")),
                    );
                    return;
                  }

                  final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

                  try {
                    await _api.createPlan(
                      email: email,
                      title: title.trim(),
                      restaurantName: restaurantName.trim().isNotEmpty ? restaurantName.trim() : null,
                      date: dateStr,
                      time: time.trim().isNotEmpty ? time.trim() : "19:00",
                      notes: notes.trim().isNotEmpty ? notes.trim() : null,
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Plan created! ✅")),
                    );

                    await _loadPlans();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: ${e.toString().replaceFirst('Exception: ', '')}")),
                    );
                  }
                },
                child: const Text('Create', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPlanDetailsDialog(PlanItem plan) {
    String editTitle = plan.title;
    String editLocation = plan.restaurantName;
    String editDate = plan.date;
    String editTime = plan.time;
    String editNotes = plan.notes;
    bool isEditing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Plan' : 'Plan Details',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                if (!isEditing)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            isEditing = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 18, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Delete Plan"),
                              content: const Text("Are you sure you want to delete this plan?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await _api.deletePlan(planId: plan.id);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Plan deleted ✅")),
                              );
                              await _loadPlans();
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: ${e.toString()}")),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.delete, size: 18, color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEditing) ...[
                    const Text('Event Title', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (v) => editTitle = v,
                      controller: TextEditingController(text: editTitle),
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                    const SizedBox(height: 16),
                    const Text('Restaurant', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (v) => editLocation = v,
                      controller: TextEditingController(text: editLocation),
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                    const SizedBox(height: 16),
                    const Text('Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (v) => editTime = v,
                      controller: TextEditingController(text: editTime),
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                    const SizedBox(height: 16),
                    const Text('Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (v) => editNotes = v,
                      controller: TextEditingController(text: editNotes),
                      maxLines: 2,
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ] else ...[
                    _detailRow(Icons.event, 'Event', editTitle),
                    const SizedBox(height: 16),
                    _detailRow(Icons.location_on, 'Location', editLocation.isNotEmpty ? editLocation : "—"),
                    const SizedBox(height: 16),
                    _detailRow(Icons.calendar_today, 'Date', editDate),
                    const SizedBox(height: 16),
                    _detailRow(Icons.schedule, 'Time', editTime),
                    const SizedBox(height: 16),
                    _detailRow(Icons.notes, 'Notes', editNotes.isNotEmpty ? editNotes : "—"),
                  ],
                ],
              ),
            ),
            actions: [
              if (isEditing)
                TextButton(
                  onPressed: () => setDialogState(() => isEditing = false),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
              if (isEditing)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  onPressed: () async {
                    if (editTitle.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Title cannot be empty")),
                      );
                      return;
                    }

                    try {
                      await _api.updatePlan(
                        planId: plan.id,
                        title: editTitle.trim(),
                        restaurantName: editLocation.trim(),
                        time: editTime.trim(),
                        notes: editNotes.trim(),
                      );

                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Plan updated! ✅")),
                      );
                      await _loadPlans();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: ${e.toString()}")),
                      );
                    }
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              if (!isEditing)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.grey)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.black),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = Session.email.trim();
    int daysInMonth = getDaysInMonth(currentMonth, currentYear);
    int firstDay = getFirstDayOfMonth(currentMonth, currentYear);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Plans',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadPlans,
          ),
        ],
      ),
      floatingActionButton: email.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: accent,
              onPressed: _showCreatePlanDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadPlans,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (email.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Logged in as: $email",
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ),

              // Calendar Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Month Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 20),
                          onPressed: previousMonth,
                        ),
                        Text(
                          '${monthNames[currentMonth - 1]} $currentYear',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 20),
                          onPressed: nextMonth,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Day Headers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: dayNames
                          .map((day) => Text(day, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[400], letterSpacing: 0.5)))
                          .toList(),
                    ),
                    const SizedBox(height: 16),

                    // Calendar Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: firstDay + daysInMonth,
                      itemBuilder: (context, index) {
                        if (index < firstDay) return const SizedBox();

                        int day = index - firstDay + 1;
                        bool isSelected = day == selectedDate.day && currentMonth == selectedDate.month && currentYear == selectedDate.year;

                        // Check if there's a plan on this day
                        final dateStr = "$currentYear-${currentMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
                        final hasPlan = _plans.any((p) => p.date == dateStr);

                        return GestureDetector(
                          onTap: () => setState(() => selectedDate = DateTime(currentYear, currentMonth, day)),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? accentOrange : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                                if (hasPlan && !isSelected)
                                  Positioned(
                                    bottom: 4,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Plans for selected date
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: planYellow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${selectedDate.day} ${monthNames[selectedDate.month - 1]}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        if (email.isNotEmpty)
                          GestureDetector(
                            onTap: _showCreatePlanDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 16, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (_plansForSelectedDate.isEmpty)
                      Text(
                        "No plans for this date",
                        style: TextStyle(color: Colors.grey[700]),
                      )
                    else
                      ..._plansForSelectedDate.map((plan) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () => _showPlanDetailsDialog(plan),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            plan.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          plan.time,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (plan.restaurantName.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 16, color: Colors.black),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              plan.restaurantName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
