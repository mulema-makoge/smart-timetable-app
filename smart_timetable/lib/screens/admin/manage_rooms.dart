import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageRooms extends StatefulWidget {
  const ManageRooms({super.key});

  @override
  State<ManageRooms> createState() => _ManageRoomsState();
}

class _ManageRoomsState extends State<ManageRooms> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  String? _errorMessage;
  String? _editingId;

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Room name cannot be empty.');
      return false;
    }
    if (_capacityController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Capacity cannot be empty.');
      return false;
    }
    if (int.tryParse(_capacityController.text.trim()) == null) {
      setState(() => _errorMessage = 'Capacity must be a number.');
      return false;
    }
    return true;
  }

  Future<void> _saveRoom() async {
    if (!_validate()) return;
    setState(() => _errorMessage = null);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'capacity': int.parse(_capacityController.text.trim()),
      };

      if (_editingId != null) {
        await _db.collection('rooms').doc(_editingId).update(data);
      } else {
        await _db.collection('rooms').add(data);
      }

      _nameController.clear();
      _capacityController.clear();
      setState(() => _editingId = null);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save room. Try again.');
    }
  }

  Future<void> _deleteRoom(String id) async {
    try {
      await _db.collection('rooms').doc(id).delete();
    } catch (e) {
      setState(
          () => _errorMessage = 'Failed to delete room. Try again.');
    }
  }

  void _editRoom(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _nameController.text = data['name'];
    _capacityController.text = data['capacity'].toString();
    setState(() => _editingId = doc.id);
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
            _editingId != null ? 'Edit Room' : 'Add New Room',
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
              labelText: 'Room Name',
              hintText: 'e.g. Room A1',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Capacity',
              hintText: 'e.g. 50',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(_errorMessage!,
                style:
                    const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveRoom,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F5C8B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                Text(_editingId != null ? 'Update Room' : 'Add Room'),
          ),
          if (_editingId != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                _nameController.clear();
                _capacityController.clear();
                setState(() => _editingId = null);
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
      stream: _db.collection('rooms').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No rooms added yet.'));
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
                  child: Icon(Icons.meeting_room_outlined,
                      color: Color(0xFF1F5C8B), size: 20),
                ),
                title: Text(data['name'],
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Capacity: ${data['capacity']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: Color(0xFF1F5C8B)),
                      onPressed: () => _editRoom(doc),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      onPressed: () => _deleteRoom(doc.id),
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