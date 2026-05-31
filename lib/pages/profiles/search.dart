import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/users_service.dart';
import 'package:mobile_app/widgets/avatar.dart';

class SearchUsersPage extends StatefulWidget {
  const SearchUsersPage({super.key});

  @override
  State<SearchUsersPage> createState() => _SearchUsersPageState();
}

class _SearchUsersPageState extends State<SearchUsersPage> {
  static const int _take = 6;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<UserProfile> _results = [];
  String _currentQuery = '';
  int _skip = 0;
  bool _hasMore = true;

  bool _initialLoading = false;
  bool _searchLoading = false;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchUsers(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _fetchUsers();
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _currentQuery = value.trim();
      _fetchUsers(reset: true);
    });
  }

  Future<void> _fetchUsers({bool reset = false}) async {
    if (!reset && (_loadingMore || !_hasMore)) return;
    if (reset && (_initialLoading || _searchLoading)) return;

    if (reset) {
      setState(() {
        _results = [];
        _skip = 0;
        _hasMore = true;
        if (_currentQuery.isEmpty) {
          _initialLoading = true;
        } else {
          _searchLoading = true;
        }
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final users = _currentQuery.isEmpty
          ? await UserService.getUsers(take: _take, skip: _skip)
          : await UserService.searchUsers(
              query: _currentQuery,
              take: _take,
              skip: _skip,
            );

      setState(() {
        _results.addAll(users);
        _skip += users.length;
        _hasMore = users.length == _take;
        _initialLoading = false;
        _searchLoading = false;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() {
        _initialLoading = false;
        _searchLoading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar usuarios...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_initialLoading || _searchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron usuarios',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _results.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final user = _results[index];

        return ListTile(
          leading: CustomAvatar(url: user.imageUrl),
          title: Text(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('@${user.username}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/user-posts/${user.id}'),
        );
      },
    );
  }
}
