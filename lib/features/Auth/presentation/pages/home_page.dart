
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String? username; // Pass from auth after login

  const HomePage({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat App"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: implement logout (FirebaseAuth.instance.signOut() etc.)
              Navigator.of(context).pushReplacementNamed("/login");
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              "Welcome ${username ?? "User"} 👋",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          const Divider(),

          // Chat list placeholder
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Dummy chats
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text("Friend $index"),
                  subtitle: Text("Message from Friend $index"),
                  onTap: () {
                    // Navigate to a dummy chat screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(friend: "Friend $index"),
                      ),
                    );
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

class ChatScreen extends StatelessWidget {
  final String friend;
  const ChatScreen({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text("Chat with $friend")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Align(
                    alignment:
                    index % 2 == 0 ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: index % 2 == 0
                            ? Colors.grey.shade300
                            : Colors.blue.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text("Message ${index + 1}"),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // TODO: send message
                    controller.clear();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
