import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../un_authorized/api_handler.dart';
import '../widgets/app_drawer.dart';

class AttendanceSectionScreen extends StatefulWidget {
  final int classId;
  final String className;

  const AttendanceSectionScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<AttendanceSectionScreen> createState() =>
      _AttendanceSectionScreenState();
}

class _AttendanceSectionScreenState
    extends State<AttendanceSectionScreen> {

  List sections = [];
  List subjects = [];
  List students = [];

  int? selectedSectionId;
  int? selectedSubjectId;

  bool isLoadingSections = true;
  bool isLoadingStudents = false;

  @override
  void initState() {
    super.initState();
    fetchSections();
    fetchSubjects();
  }

  // ✅ Fetch Sections
  Future<void> fetchSections() async {
    try {
      final data = await handleApi(
        context,
            () => ApiService.getData("classes/${widget.classId}/sections"),
      );

      setState(() {
        sections = data ?? [];
      });
    } finally {
      setState(() => isLoadingSections = false);
    }
  }

  // ✅ Fetch Subjects
  Future<void> fetchSubjects() async {
    try {
      final data = await handleApi(
        context,
            () => ApiService.getData("classes/${widget.classId}/subjects"),
      );

      setState(() {
        subjects = data ?? [];
      });
    } catch (e) {
      subjects = [];
    }
  }

  // ✅ Fetch Students
  Future<void> fetchStudents(int sectionId) async {
    setState(() => isLoadingStudents = true);

    try {
      final data = await handleApi(
        context,
            () => ApiService.getData("sections/$sectionId/students"),
      );

      setState(() {
        students = (data ?? []).map((s) {
          s['isPresent'] = false; // default absent
          return s;
        }).toList();
      });
    } finally {
      setState(() => isLoadingStudents = false);
    }
  }

  // ✅ Submit Attendance
  Future<void> submitAttendance() async {
    print("🚀 Submit button clicked");

    if (selectedSectionId == null || selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select section & subject")),
      );
      return;
    }

    final payload = {
      "class_id": widget.classId,
      "subject_id": selectedSubjectId,
      "students": students.map((s) {
        return {
          "id": s['id'],
          "status": s['isPresent'] ? "present" : "absent",
        };
      }).toList()
    };

    print("📦 Payload: $payload");

    try {
      final response = await handleApi(
        context,
            () => ApiService.saveAttendance("attendance/mark", payload),
      );

      print("✅ API Response: $response");

      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Success")),
        );

        setState(() {
          for (var s in students) {
            s['isPresent'] = false;
          }
        });

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?['message'] ?? "Something went wrong"),
          ),
        );

        print("❌ ERROR: ${response?['error']}");
      }

    } catch (e) {
      print("🔥 ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ✅ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance : ${widget.className}"),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [

          // ✅ Section Dropdown
          Padding(
            padding: const EdgeInsets.all(8),
            child: isLoadingSections
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<int>(
              hint: const Text("Select Section"),
              value: selectedSectionId,
              items: sections.map<DropdownMenuItem<int>>((s) {
                return DropdownMenuItem(
                  value: s['id'],
                  child: Text(s['section_name']),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => selectedSectionId = val);
                if (val != null) fetchStudents(val);
              },
            ),
          ),

          // ✅ Subject Dropdown
          Padding(
            padding: const EdgeInsets.all(8),
            child: DropdownButtonFormField<int>(
              hint: const Text("Select Subject"),
              value: selectedSubjectId,
              items: subjects.map<DropdownMenuItem<int>>((s) {
                return DropdownMenuItem(
                  value: s['id'],
                  child: Text(s['subject_name']),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => selectedSubjectId = val);
              },
            ),
          ),

          // ✅ Students List
          Expanded(
            child: isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : students.isEmpty
                ? const Center(child: Text("No students"))
                : ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final s = students[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                    s['user']?['profile_photo'] != null
                        ? NetworkImage(
                        s['user']['profile_photo'])
                        : const AssetImage(
                        'assets/images/B.png')
                    as ImageProvider,
                  ),
                  title: Text(s['user']?['name'] ?? "Student"),
                  subtitle:
                  Text("Roll: ${s['roll_number'] ?? ''}"),
                  trailing: Checkbox(
                    value: s['isPresent'],
                    onChanged: (val) {
                      setState(() {
                        s['isPresent'] = val;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // ✅ Submit Button
          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: submitAttendance,
              child: const Text("Submit Attendance"),
            ),
          ),
        ],
      ),
    );
  }
}