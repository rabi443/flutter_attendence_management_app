import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../un_authorized/api_handler.dart';
import '../widgets/app_drawer.dart';

class TeachersScreen extends StatefulWidget {
  final String title;
  final String endpoint;

  const TeachersScreen({
    super.key,
    required this.title,
    required this.endpoint,
  });

  @override
  _TeachersScreenState createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  List<dynamic> data = [];
  List<dynamic> filteredData = [];

  bool loading = true;
  bool isConnected = true;
  bool isUnauthorized = false;

  int currentPage = 1;
  int perPage = 20;

  TextEditingController searchController = TextEditingController();

  List<String> get tableHeaders {
    if (widget.endpoint == 'teachers') {
      return ["ID", "Name", "Email", "Role", "Action"];
    }
    return ["ID", "Name", "Email", "Actions"];
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await checkInternet();
    if (isConnected) {
      await fetchData();
    }
  }

  Future<void> checkInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    bool nowConnected = connectivityResult != ConnectivityResult.none;
    setState(() => isConnected = nowConnected);

    if (!nowConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No Internet Connection ❌"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> refreshPage() async {
    await checkInternet();
    if (isConnected) await fetchData();
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    if (!isConnected) {
      setState(() => loading = false);
      return;
    }

    try {
      final result = await handleApi(
        context,
            () => ApiService.getData(widget.endpoint),
      );

      setState(() {
        data = result ?? [];
        filteredData = data;
        loading = false;
        currentPage = 1;
      });
    } catch (e) {
      setState(() => loading = false);
      if (e is UnauthorizedException) {
        setState(() => isUnauthorized = true);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch data")),
      );
    }
  }

  void filterData(String query) {
    if (query.isEmpty) {
      setState(() => filteredData = data);
    } else {
      setState(() {
        filteredData = data
            .where((item) => item.values.any(
                (v) => v.toString().toLowerCase().contains(query.toLowerCase())))
            .toList();
        currentPage = 1;
      });
    }
  }

  void confirmDelete(dynamic id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    ) ??
        false;

    if (confirm) deleteItem(id);
  }

  void deleteItem(dynamic id) async {
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No Internet Connection")),
      );
      return;
    }

    int parsedId = int.parse(id.toString());
    bool? success;

    try {
      success = await handleApi(
        context,
            () => ApiService.deleteData(widget.endpoint, parsedId),
      );
    } catch (e) {
      success = false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success == true ? "Deleted successfully" : "Failed to delete"),
      ),
    );

    if (success == true) fetchData();
  }

  void openForm({Map<String, dynamic>? item}) {
    final formKey = GlobalKey<FormState>();
    Map<String, dynamic> formData = {};

    if (item != null) {
      formData = {
        "name": item['user']?['name'] ?? '',
        "email": item['user']?['email'] ?? '',
        "role": item['user']?['role'] ?? '',
      };
    }

    List<String> allowedFields = ["name", "email", "role"];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item != null ? "Edit Teacher" : "Add Teacher"),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: allowedFields.map((k) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextFormField(
                    initialValue: formData[k]?.toString() ?? '',
                    decoration: InputDecoration(
                      labelText: k,
                      border: const OutlineInputBorder(),
                    ),
                    onSaved: (val) => formData[k] = val,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (!isConnected) return;

              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();

                bool? success;

                try {
                  if (item != null) {
                    int id = int.parse(item['id'].toString());

                    Map<String, dynamic> payload = {
                      "name": formData['name'],
                      "email": formData['email'],
                      "role": formData['role'],
                    };

                    success = await handleApi(
                      context,
                          () => ApiService.updateData(widget.endpoint, id, payload),
                    );
                  } else {
                    success = await handleApi(
                      context,
                          () => ApiService.createData(widget.endpoint, formData),
                    );
                  }

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success == true
                            ? (item != null ? "Updated!" : "Created!")
                            : "Failed",
                      ),
                    ),
                  );

                  if (success == true) fetchData();
                } catch (e) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isUnauthorized) return const SizedBox();

    int totalPages = (filteredData.length / perPage).ceil();
    int start = (currentPage - 1) * perPage;
    int end = (start + perPage > filteredData.length) ? filteredData.length : start + perPage;
    List<dynamic> pageData = filteredData.sublist(start, end);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: refreshPage,
        child: ListView(
          padding: const EdgeInsets.all(16), // padding around everything
          children: [
            if (!isConnected)
              const Text("No Internet Connection", style: TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: "Search...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: filterData,
            ),
            const SizedBox(height: 16),

            // Table with horizontal scroll
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: tableHeaders.map((header) => DataColumn(label: Text(header))).toList(),
                rows: pageData.isEmpty
                    ? [
                  DataRow(
                    cells: [
                      DataCell(Text("No records available", style: TextStyle(color: Colors.grey))),
                      ...List.generate(tableHeaders.length - 1, (_) => DataCell.empty),
                    ],
                  )
                ]
                    : pageData.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(Text(item['id'].toString())),
                      DataCell(Text(item['user']?['name'] ?? '')),
                      DataCell(Text(item['user']?['email'] ?? '')),
                      if (widget.endpoint == 'teachers') DataCell(Text(item['user']?['role'] ?? '')),
                      DataCell(
                        SizedBox(
                          width: 100, // fixed width for the cell
                          child: Row(
                            // mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => openForm(item: item)),
                              IconButton(icon: const Icon(Icons.delete), onPressed: () => confirmDelete(item['id'])),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Pagination buttons
            if (totalPages > 1) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
                    child: const Text("Previous"),
                  ),
                  const SizedBox(width: 20),
                  Text("Page $currentPage of $totalPages"),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: currentPage < totalPages ? () => setState(() => currentPage++) : null,
                    child: const Text("Next"),
                  ),
                ],
              ),
              const SizedBox(height: 50), // extra spacing at bottom
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}