import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/manager.dart';
import '../model/match.dart';

class NewmatchScreen extends StatelessWidget {

  const NewmatchScreen({super.key, required this.selectedSport});
  final String selectedSport;  
  @override
  AlertDialog build(BuildContext context) {
    final manager = Provider.of<Manager>(context);
    final dateController = TextEditingController(text: '');
    final nameController = TextEditingController(text: '');
    final descriptionController = TextEditingController(text: '');

    return AlertDialog(
            title: const Text('Nova Partida'),
            content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome da partida'),
                ),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Data'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                DropdownButtonFormField(
                  decoration: const InputDecoration(
                    labelText: 'Select Field',
                    border: OutlineInputBorder(),
                  ),
                  items: manager.fields.map((field) {
                    return DropdownMenuItem(
                      value: field,
                      child: Text(field.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      manager.selectField(value);
                    }
                  },
                ),
                DropdownButtonFormField(
                  decoration: const InputDecoration(
                    labelText: 'Select Player',
                    border: OutlineInputBorder(),
                  ),
                  items: manager.players.map((player) {
                    return DropdownMenuItem(
                      value: player,
                      child: Text(player.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      manager.selectPlayer(value);
                    }
                  },
                ),            
              ],
            ),
          ),
        actions: [
          TextButton(
            onPressed: () {
              manager.updateSport('');
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text;
              final date = dateController.text;
              final description = descriptionController.text;
              if(name!='' && date != '' && description != '' && manager.selectedField != null && manager.selectedPlayer != null){
                final newMatch = Match(
                  id: manager.getNextPlayerId(),
                  name: name,
                  description: description,
                  date: date,
                  field: manager.selectedField,
                  player: manager.selectedPlayer
                );
                manager.addMatch(newMatch);
              }
              manager.updateSport(selectedSport);
              Navigator.of(context).pop();
            },
            child: const Text('Criar Nova Partida'),
          ),
        ],
      );
  }
}