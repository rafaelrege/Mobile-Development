import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ListScreen extends StatefulWidget {
  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List _users = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      setState(() {
        _errorMessage = 'No token found. Please login again.';
      });
      return;
    }

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    var request = http.Request('GET', Uri.parse('http://localhost:3030/users'));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseBody = await response.stream.bytesToString();
      setState(() {
        _users = jsonDecode(responseBody);
      });
    } else {
      setState(() {
        _errorMessage = 'Failed to fetch users: ${response.reasonPhrase}';
      });
    }
  }

  void _editUser(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditScreen(user: _users[index]),
      ),
    ).then((_) {
      _fetchUsers();
    });
  }

  void _addUser() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddUserScreen(),
      ),
    ).then((_) {
      _fetchUsers();
    });
  }

  Future<void> _deleteUser(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      return;
    }

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var response = await http.delete(
      Uri.parse('http://localhost:3030/users/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      setState(() {
        _users.removeWhere((user) => user['id'] == id);
      });
      print('User deleted: $id');
    } else {
      print('Failed to delete user: ${response.reasonPhrase}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Usuários'),
      ),
      body: _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: <Widget>[
                          Text(
                            'ID: ${_users[index]['id']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ListTile(
                            title: Text(_users[index]['name']),
                            subtitle: Text(_users[index]['username']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editUser(index),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () =>
                                      _deleteUser(_users[index]['id']),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: _addUser,
                  child: Text('Adicionar Usuário'),
                ),
              ],
            ),
    );
  }
}

class EditScreen extends StatefulWidget {
  final Map user;

  EditScreen({required this.user});

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']);
    _usernameController = TextEditingController(text: widget.user['username']);
  }

  Future<void> _updateUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      return;
    }

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var body = jsonEncode({
      'name': _nameController.text,
      'username': _usernameController.text,
      'roles': widget.user['roles'],
      'password': widget.user['password'],
    });

    var response = await http.put(
      Uri.parse('http://localhost:3030/users/${widget.user['id']}'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      print('User updated: ${response.body}');
      Navigator.pop(context, true);
    } else {
      print('Failed to update user: ${response.reasonPhrase}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Usuário'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text('ID: ${widget.user['id']}'),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateUser,
              child: Text('Atualizar'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddUserScreen extends StatefulWidget {
  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _addUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      return;
    }

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var body = jsonEncode({
      'name': _nameController.text,
      'username': _usernameController.text,
      'roles': ['user'],
      'password': _passwordController.text,
    });

    var response = await http.post(
      Uri.parse('http://localhost:3030/users'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 201) {
      print('User added: ${response.body}');
      Navigator.pop(context, true);
    } else {
      print('Failed to add user: ${response.reasonPhrase}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addUser,
              child: Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }
}
