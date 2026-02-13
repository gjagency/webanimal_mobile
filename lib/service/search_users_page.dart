import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/posts_service.dart';

class SearchUsersPage extends StatefulWidget {
  const SearchUsersPage({super.key});

  @override
  State<SearchUsersPage> createState() => _SearchUsersPageState();
}
class _SearchUsersPageState extends State<SearchUsersPage> {

  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<PostUser> _results = [];
  bool _loading = false;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialUsers(); // 👈 CARGA AUTOMÁTICA AL ENTRAR
  }

Future<void> _loadInitialUsers() async {
  setState(() => _initialLoading = true);

  try {
    final users = await PostsService.getUsers();

    setState(() {
      _results = users;
      _initialLoading = false;
    });
  } catch (e) {
    setState(() => _initialLoading = false);
  }
}


  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchUsers(value);
    });
  }

Future<void> _searchUsers(String query) async {
  if (query.isEmpty) {
    _loadInitialUsers();
    return;
  }

  setState(() => _loading = true);

  try {
    final users = await PostsService.searchUsers(query);

    setState(() {
      _results = users;
      _loading = false;
    });
  } catch (e) {
    setState(() => _loading = false);
  }
}


  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar usuarios...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: Column(
  children: [
    Expanded(
      child: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontraron usuarios',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final user = _results[index];


                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            user.imageUrl != null ? NetworkImage(user.imageUrl!) : null,
                        child: user.imageUrl == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('@${user.username}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                      context.push('/user-posts/${user.id}');
                    },
                    );
                      },
                    ),
    ),
  ],
),

    );
  }
}
