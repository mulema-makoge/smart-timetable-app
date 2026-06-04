import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageLecturers extends StatefulWidget {
  const ManageLecturers({super.key});

  @override
  State<ManageLecturers> createState() => _ManageLecturersState();
}

class _ManageLecturersState extends State<ManageLecturers> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _errorMessage;
  String? _editingId;
  String? _selectedCourseId;
  String? _selectedCourseName;
  List<QueryDocumentSnapshot> _coursesDocs = [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) {
      setState(
          () => _errorMessage = 'Lecturer name cannot be empty.');
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Email cannot be empty.');
      return false;
    }
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text.trim())) {
      setState(() => _errorMessage =
          'Please enter a valid email address.');
      return false;
    }
    if (_selectedCourseId == null) {
      setState(
          () => _errorMessage = 'Please assign a course.');
      return false;
    }
    return true;
  }

  Future<void> _saveLecturer() async {
    if (!_validate()) return;
    setState(() => _errorMessage = null);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'courseId': _selectedCourseId,
        'courseName': _selectedCourseName,
      };

      if (_editingId != null) {
        await _db
            .collection('lecturers')
            .doc(_editingId)
            .update(data);
      } else {
        await _db.collection('lecturers').add(data);
      }

      _nameController.clear();
      _emailController.clear();
      setState(() {
        _editingId = null;
        _selectedCourseId = null;
        _selectedCourseName = null;
      });
    } catch (e) {
      setState(() =>
          _errorMessage = 'Failed to save lecturer. Try again.');
    }
  }

  Future<void> _deleteLecturer(String id) async {
    try {
      await _db.collection('lecturers').doc(id).delete();
    } catch (e) {
      setState(() =>
          _errorMessage = 'Failed to delete lecturer. Try again.');
    }
  }

  void _editLecturer(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _nameController.text = data['name'];
    _emailController.text = data['email'];
    setState(() {
      _editingId = doc.id;
      _selectedCourseId = data['courseId'];
      _selectedCourseName = data['courseName'];
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
            _editingId != null
                ? 'Edit Lecturer'
                : 'Add New Lecturer',
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
              labelText: 'Full Name',
              hintText: 'e.g. Dr. John Smith',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'e.g. john.smith@ub.cm',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('courses').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              _coursesDocs = snapshot.data!.docs;

              final validIds =
                  _coursesDocs.map((d) => d.id).toList();
              if (_selectedCourseId != null &&
                  !validIds.contains(_selectedCourseId)) {
                _selectedCourseId = null;
                _selectedCourseName = null;
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedCourseId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: const Text('Assign a Course'),
                  items: _coursesDocs.map((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    final selected = _coursesDocs.firstWhere(
                      (doc) => doc.id == value,
                    );
                    final data =
                        selected.data() as Map<String, dynamic>;
                    setState(() {
                      _selectedCourseId = value;
                      _selectedCourseName = data['name'];
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
            onPressed: _saveLecturer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F5C8B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_editingId != null
                ? 'Update Lecturer'
                : 'Add Lecturer'),
          ),
          if (_editingId != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                _nameController.clear();
                _emailController.clear();
                setState(() {
                  _editingId = null;
                  _selectedCourseId = null;
                  _selectedCourseName = null;
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
      stream: _db.collection('lecturers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No lecturers added yet.'));
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
                  child: Icon(Icons.person_outlined,
                      color: Color(0xFF1F5C8B), size: 20),
                ),
                title: Text(data['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${data['email']} • ${data['courseName'] ?? 'No course assigned'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: Color(0xFF1F5C8B)),
                      onPressed: () => _editLecturer(doc),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      onPressed: () => _deleteLecturer(doc.id),
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
                child:
                    SingleChildScrollView(child: _buildList()),
              ),
            ],
          );
  }
}