import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../map/providers/business_provider.dart';

class FloatingSearchBar extends ConsumerStatefulWidget {
  final VoidCallback? onMenuTap;
  
  const FloatingSearchBar({super.key, this.onMenuTap});

  @override
  ConsumerState<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends ConsumerState<FloatingSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isSearching = true;
            });
          },
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_isSearching) {
                       // Clear search
                       setState(() {
                         _isSearching = false;
                         _controller.clear();
                         ref.read(searchQueryProvider.notifier).state = '';
                         FocusScope.of(context).unfocus();
                       });
                    } else {
                       widget.onMenuTap?.call();
                    }
                  },
                  child: Icon(
                    _isSearching ? Icons.arrow_back : Icons.menu, 
                    color: Colors.white70
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _isSearching 
                  ? TextField(
                      controller: _controller,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search tacos, mechanics...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        ref.read(searchQueryProvider.notifier).state = value;
                      },
                    )
                  : Text(
                    _controller.text.isEmpty ? 'Where to?' : _controller.text,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_isSearching && _controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                    child: const Icon(Icons.close, color: Colors.white70),
                  )
                else
                  const Icon(Icons.search, color: Colors.blueAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
