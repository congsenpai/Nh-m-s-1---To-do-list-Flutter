import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


void main() {
  runApp(MyApp());
}
class Todo {
  int? userId;
  int? id;
  String title;
  bool completed;

  Todo({
    this.userId,
    this.id,
    required this.title,
    this.completed = false,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      userId: json['userId'],
      id: json['id'],
      title: json['title'],
      completed: json['completed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'id': id,
      'title': title,
      'completed': completed,
    };
  }
}

class ApiService {
  final String baseUrl = "https://jsonplaceholder.typicode.com/todos";

  Future<List<Todo>> fetchTodos() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Todo> todos = body.map((dynamic item) => Todo.fromJson(item)).toList();
      return todos;
    } else {
      throw Exception('Failed to load todos');
    }
  }

  Future<Todo> createTodo(Todo todo) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(todo.toJson()),
    );

    if (response.statusCode == 201) {
      return Todo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create todo');
    }
  }

  Future<void> updateTodo(Todo todo) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${todo.id}'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(todo.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update todo');
    }
  }

  Future<void> deleteTodo(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete todo');
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Todo>> futureTodos;

  @override
  void initState() {
    super.initState();
    futureTodos = apiService.fetchTodos();
  }

  void _addTodo() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController titleController = TextEditingController();

        return AlertDialog(
          title: Text('Add New To-Do'),
          content: TextField(
            controller: titleController,
            decoration: InputDecoration(hintText: "Enter task title"),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  apiService.createTodo(Todo(title: titleController.text)).then((todo) {
                    setState(() {
                      futureTodos = apiService.fetchTodos();
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Todo added: ${todo.title}')));
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
                  });
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }


  void _deleteTodo(int id, String title) {
    apiService.deleteTodo(id).then((_) {
      setState(() {
        futureTodos = apiService.fetchTodos();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Todo deleted: $title')));
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
    });
  }



  void _updateTodo(Todo todo) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController titleController = TextEditingController(text: todo.title);

        return AlertDialog(
          title: Text('Edit To-Do'),
          content: TextField(
            controller: titleController,
            decoration: InputDecoration(hintText: "Enter task title"),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  Todo updatedTodo = Todo(
                    id: todo.id,
                    title: titleController.text,
                    completed: todo.completed,
                  );
                  apiService.updateTodo(updatedTodo).then((_) {
                    setState(() {
                      futureTodos = apiService.fetchTodos();
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Todo updated: ${updatedTodo.title}')));
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
                  });
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addTodo,
          )
        ],
      ),
      body: FutureBuilder<List<Todo>>(
        future: futureTodos,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Todo todo = snapshot.data![index];
                return ListTile(
                  title: Text(
                    todo.title,
                    style: TextStyle(
                      decoration: todo.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _updateTodo(todo);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteTodo(todo.id!,todo.title);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
