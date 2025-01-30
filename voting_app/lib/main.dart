import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voting App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VotingScreen(),
    );
  }
}

class VotingScreen extends StatefulWidget {
  @override
  _VotingScreenState createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  List<dynamic> candidates = [];
  TextEditingController candidateNameController = TextEditingController();
  TextEditingController voterAddressController = TextEditingController();
  TextEditingController adminAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCandidates();
  }

  Future<void> fetchCandidates() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/candidates'));

      // Log the response status and body
      // print('Response Status: ${response.statusCode}');
      // print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          candidates = json.decode(response.body);
        });
      } else {
        print('Failed to load candidates, status code: ${response.statusCode}');
        throw Exception('Failed to load candidates');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }


  Future<void> addCandidate(String name, String adminAddress) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/addCandidate'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'adminAddress': adminAddress}),
    );
    if (response.statusCode == 200) {
      fetchCandidates();
    } else {
      throw Exception('Failed to add candidate');
    }
  }

  Future<void> vote(int candidateId, String voterAddress) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/vote'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'candidateId': candidateId, 'voterAddress': voterAddress}),
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      fetchCandidates();
      // Ensure to parse any numeric values from String to int
      final candidateId = int.tryParse(result['candidateId']) ?? 0;
      final voteCount = int.tryParse(result['voteCount']) ?? 0;

      print('Voted for candidate: $candidateId, Vote count: $voteCount');

      // Proceed with your next actions like fetching candidates

    } else {
      throw Exception('Failed to vote');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voting App'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                return ListTile(
                  title: Text(candidate['name']),
                  subtitle: Text('Votes: ${candidate['voteCount']}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      vote(int.parse(candidate['id']), voterAddressController.text);
                    },
                    child: Text('Vote'),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: voterAddressController,
              decoration: InputDecoration(
                labelText: 'Your Address',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: candidateNameController,
              decoration: InputDecoration(
                labelText: 'Candidate Name',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: adminAddressController,
              decoration: InputDecoration(
                labelText: 'Admin Address',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              addCandidate(candidateNameController.text, adminAddressController.text);
            },
            child: Text('Add Candidate'),
          ),
        ],
      ),
    );
  }
}