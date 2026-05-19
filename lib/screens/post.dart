import 'package:flutter/material.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _rating = 0;
  String _price = 'Cheap';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Widget _star(int index) {
    final filled = index <= _rating;
    return IconButton(
      icon: Icon(
        filled ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 36,
      ),
      onPressed: () => setState(() => _rating = index),
      splashRadius: 20,
    );
  }

  Widget _priceBtn(String label) {
    final selected = _price == label;
    return GestureDetector(
      onTap: () => setState(() => _price = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E3A9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black26, offset: const Offset(0, 4), blurRadius: 6),
          ],
          border: Border.all(color: selected ? Colors.black54 : Colors.transparent),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFFEF9EE);
    const Color accent = Color(0xFF6F8574);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Post', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // image placeholder
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: Colors.black26, offset: const Offset(0, 6), blurRadius: 10)],
                ),
                child: const Center(child: Icon(Icons.add, size: 36)),
              ),

              const SizedBox(height: 18),
              const Text('Restaurant name', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Restaurant Name',
                  filled: true,
                  fillColor: Colors.grey[300],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 18),
              const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                minLines: 5,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Add description ...',
                  filled: true,
                  fillColor: Colors.grey[300],
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 18),
              const Text('Rating', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              // centered rating stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => _star(i + 1)),
              ),

              const SizedBox(height: 18),
              const Text('Price Range', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              // centered price range buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _priceBtn('Cheap'),
                  _priceBtn('Reasonable'),
                  _priceBtn('Expensive'),
                ],
              ),

              const SizedBox(height: 30),
              // post button
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posted')));
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 8,
                    ),
                    child: const Text(
                      'Post',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}