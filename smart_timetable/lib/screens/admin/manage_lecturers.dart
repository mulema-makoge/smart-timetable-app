import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageCourses extends StatefulWidget {
  const ManageCourses({super.key});

  @override
  State<ManageCourses> createState() => _ManageCoursesState();
}

class _ManageCoursesState extends State<ManageCourses> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  String? _errorMessage;
  String? _editingId;
  String? _selectedClassId;
  String? _selectedClassName;
  List<QueryDocumentSnapshot> _classesDocs = [];

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Course name cannot be empty.');
      return false;
    }
    if (_codeController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Course code cannot be empty.');
      return false;
    }
    if (_selectedClassId == null) {
      setState(() => _errorMessage = 'Please select a class.');
      return false;
    }
    return true;
  }

  Future<void> _saveCourse() async {
    if (!_validate()) return;
    setState(() => _errorMessage = null);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim(),
        'classId': _selectedClassId,
        'className': _selectedClassName,
      };

      if (_editingId != null) {
        await _db.collection('courses').doc(_editingId).update(data);
      } else {
        await _db.collection('courses').add(data);
      }

      _nameController.clear();
      _codeController.clear();
      setState(() {
        _editingId = null;
        _selectedClassId = null;
        _selectedClassName = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save course. Try again.');
    }
  }

  Future<void> _deleteCourse(String id) async {
    try {
      await _db.collection('courses').doc(id).delete();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to delete course. Try again.');
    }
  }

  void _editCourse(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _nameController.text = data['name'];
    _codeController.text = data['code'];
    setState(() {
      _editingId = doc.id;
      _selectedClassId = data['classId'];
      _selectedClassName = data['className'];
    });
  }

  Widget _buildForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _editingId != null ? 'Edit Course' : 'Add New Course',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F5C8B),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Course Name',
              hintText: 'e.g. Computer Networks',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Course Code',
              hintText: 'e.g. CEC 301',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('classes').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              _classesDocs = snapshot.data!.docs;

              final validIds =
                  _classesDocs.map((d) => d.id).toList();
              if (_selectedClassId != null &&
                  !validIds.contains(_selectedClassId)) {
                _selectedClassId = null;
                _selectedClassName = null;
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedClassId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: const Text('Assign to Class'),
                  items: _classesDocs.map((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    final selected = _classesDocs.firstWhere(
                      (doc) => doc.id == value,
                    );
                    final data =
                        selected.data() as Map<String, dynamic>;
                    setState(() {
                      _selectedClassId = value;
                      _selectedClassName = data['name'];
                    });
                  },
                ),
              );
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(_errorMessage!,
                style: const TextStyle(
                    color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveCourse,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F5C8B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
                _editingId != null ? 'Update Course' : 'Add Course'),
          ),
          if (_editingId != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                _nameController.clear();
                _codeController.clear();
                setState(() {
                  _editingId = null;
                  _selectedClassId = null;
                  _selectedClassName = null;
                });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('courses').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No courses added yet.'));
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE6F1FB),
                  child: Icon(Icons.book_outlined,
                      color: Color(0xFF1F5C8B), size: 20),
                ),
                title: Text(data['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${data['code']} • ${data['className'] ?? 'No class assigned'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: Color(0xFF1F5C8B)),
                      onPressed: () => _editCourse(doc),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      onPressed: () => _deleteCourse(doc.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return isMobile
        ? SingleChildScrollView(
            child: Column(
              children: [
                _buildForm(),
                const SizedBox(height: 24),
                _buildList(),
              ],
            ),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 320, child: _buildForm()),
              const SizedBox(width: 24),
              Expanded(
                child: SingleChildScrollView(child: _buildList()),
              ),
            ],
          );
  }
}