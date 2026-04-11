import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../un_authorized/api_handler.dart';
import '../widgets/app_drawer.dart';

class StudentsScreen extends StatefulWidget {
  final String title;
  final String endpoint;

  const StudentsScreen({
    super.key,
    required this.title,
    required this.endpoint,
  });

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<dynamic> data = [];
  List<dynamic> filteredData = [];

  List<dynamic> classes = [];
  List<dynamic> sections = [];

  dynamic selectedClassId;
  dynamic selectedSectionId;
  String? selectedGender;

  bool isConnected = true;
  bool isUnauthorized = false;

  int currentPage = 1;
  int perPage = 20;

  TextEditingController searchController = TextEditingController();

  List<String> get tableHeaders {
    return ["ID", "Name", "Email", "Role", "Gender", "Action"];
  }

  @override
  void initState() {
    super.initState();
    checkInternet();
    fetchClasses();
    fetchData();
  }

  // ---------------- INTERNET ----------------
  Future<void> checkInternet() async {
    var result = await Connectivity().checkConnectivity();
    setState(() {
      isConnected = result != ConnectivityResult.none;
    });
  }

  // ---------------- CLASSES ----------------
  Future<void> fetchClasses() async {
    final res = await handleApi(
      context,
          () => ApiService.getData("classes"),
    );

    setState(() {
      classes = res ?? [];
    });
  }

  // ---------------- SECTIONS ----------------
  Future<void> fetchSections(dynamic classId) async {
    setState(() {
      sections = [];
      selectedSectionId = null;
    });

    final res = await handleApi(
      context,
          () => ApiService.getData("classes/$classId/sections"),
    );

    setState(() {
      sections = res ?? [];
    });
  }

  // ---------------- FETCH DATA ----------------
  Future<void> fetchData() async {
    if (!isConnected) return;

    try {
      List<String> params = [];

      if (selectedClassId != null) {
        params.add("class_id=$selectedClassId");
      }

      if (selectedSectionId != null) {
        params.add("section_id=$selectedSectionId");
      }

      if (selectedGender != null && selectedGender!.isNotEmpty) {
        params.add("gender=$selectedGender");
      }

      String url = widget.endpoint;
      if (params.isNotEmpty) {
        url += "?${params.join("&")}";
      }

      final result = await handleApi(
        context,
            () => ApiService.getData(url),
      );

      setState(() {
        data = result ?? [];
        filteredData = data;
        currentPage = 1;
      });
    } catch (e) {
      if (e is UnauthorizedException) {
        setState(() => isUnauthorized = true);
      }
    }
  }

  // ---------------- SEARCH ----------------
  void filterData(String query) {
    setState(() {
      filteredData = data.where((item) {
        return item.values.any((v) =>
            v.toString().toLowerCase().contains(query.toLowerCase()));
      }).toList();
      currentPage = 1;
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    int totalPages = (filteredData.length / perPage).ceil().clamp(1, 999);

    int start = (currentPage - 1) * perPage;
    int end = (start + perPage > filteredData.length)
        ? filteredData.length
        : start + perPage;

    List pageData = filteredData.sublist(start, end);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          if (!isConnected)
            const Text("No Internet", style: TextStyle(color: Colors.red)),

          const SizedBox(height: 10),

          // ================= FILTER ROW =================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [

                // SEARCH
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: "Search...",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: filterData,
                  ),
                ),

                const SizedBox(width: 10),

                // CLASS
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField(
                    value: selectedClassId,
                    hint: const Text("Class"),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: classes.map<DropdownMenuItem>((c) {
                      return DropdownMenuItem(
                        value: c['id'],
                        child: Text(c['class_name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      setState(() {
                        selectedClassId = val;
                        selectedSectionId = null;
                      });

                      await fetchSections(val);
                      await fetchData();
                    },
                  ),
                ),

                const SizedBox(width: 10),

                // SECTION
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField(
                    value: selectedSectionId,
                    hint: const Text("Section"),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: sections.map<DropdownMenuItem>((s) {
                      return DropdownMenuItem(
                        value: s['id'],
                        child: Text(s['section_name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      setState(() {
                        selectedSectionId = val;
                      });

                      await fetchData();
                    },
                  ),
                ),

                const SizedBox(width: 10),

                // GENDER
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: selectedGender,
                    hint: const Text("Gender"),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: "male", child: Text("Male")),
                      DropdownMenuItem(value: "female", child: Text("Female")),
                    ],
                    onChanged: (val) async {
                      setState(() {
                        selectedGender = val;
                      });

                      await fetchData();
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ================= TABLE =================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: tableHeaders
                  .map((h) => DataColumn(label: Text(h)))
                  .toList(),
              rows: pageData.isEmpty
                  ? [
                DataRow(
                  cells: List.generate(
                    tableHeaders.length,
                        (i) => DataCell(
                      i == 0
                          ? const Text("No records",
                          style: TextStyle(color: Colors.grey))
                          : const Text(""),
                    ),
                  ),
                )
              ]
                  : pageData.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text("${item['id'] ?? ''}")),
                    DataCell(Text(item['user']?['name'] ?? '')),
                    DataCell(Text(item['user']?['email'] ?? '')),
                    DataCell(Text(item['user']?['role'] ?? '')),
                    DataCell(Text(item['gender'] ?? '')),
                    DataCell(Row(
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {}),
                        IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {}),
                      ],
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}