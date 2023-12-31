import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() => runApp(MaterialApp(
      home: Home(),
    ));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> tarefas = [];

  @override
  void initState() {
    super.initState();
    _listarTarefas();
  }

  Future<void> _atualizarLista() async {
    await _listarTarefas();
    setState(() {});
  }

  _recuperarBancoDados() async {
    try {
      final getDataBase = await getDatabasesPath();
      final localDataBase = join(getDataBase, "banco.db");

      var bd = await openDatabase(localDataBase, version: 2,
          onCreate: (db, dbNewest) {
        String sql =
            "CREATE TABLE tarefas (id INTEGER PRIMARY KEY AUTOINCREMENT, descricao TEXT, concluida INTEGER)";
        db.execute(sql);
      });

      print("path: $localDataBase");

      return bd;
    } catch (e) {
      print("Erro ao recuperar banco de dados: $e");
      return null;
    }
  }

  _salvarTarefa(String descricao) async {
    try {
      Database bd = await _recuperarBancoDados();

      Map<String, dynamic> novaTarefa = {
        "descricao": descricao,
        "concluida": 0,
      };

      List<Map<String, dynamic>> tarefaExistente = await bd.query(
        "tarefas",
        where: "descricao = ?",
        whereArgs: [novaTarefa["descricao"]],
      );

      if (tarefaExistente.isEmpty) {
        await bd.insert("tarefas", novaTarefa);
        print("Tarefa adicionada com sucesso!");
        await _atualizarLista();
      } else {
        print("Essa tarefa já existe");
      }
    } catch (e) {
      print("Erro ao salvar tarefa: $e");
    }
  }

  Future<void> _listarTarefas() async {
    try {
      Database bd = await _recuperarBancoDados();

      String sql = "SELECT * FROM tarefas";
      List<Map<String, dynamic>> listaTarefas = await bd.rawQuery(sql);

      setState(() {
        tarefas = listaTarefas;
      });
    } catch (e) {
      print("Erro ao listar tarefas: $e");
    }
  }

  _alternarStatusTarefa(int id, bool status) async {
    try {
      Database bd = await _recuperarBancoDados();

      await bd.update("tarefas", {"concluida": status ? 1 : 0},
          where: "id = ?", whereArgs: [id]);

      _listarTarefas();
    } catch (e) {
      print("Erro ao alternar status da tarefa: $e");
    }
  }

  _excluirTarefa(int id) async {
    try {
      Database bd = await _recuperarBancoDados();

      int retorno =
          await bd.delete("tarefas", where: "id = ?", whereArgs: [id]);

      print("Tarefa removida: $retorno");
        await _atualizarLista();
    } catch (e) {
      print("Erro ao excluir tarefa: $e");
    }
  }

  _excluirTodasTarefas() async {
    try {
      Database bd = await _recuperarBancoDados();

      int retorno = await bd.delete("tarefas");
      print("Todas as tarefas removidas: $retorno");
      _listarTarefas();
    } catch (e) {
      print("Erro ao excluir todas as tarefas: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.purple, // Cor roxa para botões e AppBar
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Lista de Tarefas'),
        ),
        body: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adicione no botão de "+" as suas tarefas:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: tarefas.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Checkbox(
                        value: tarefas[index]['concluida'] == 1,
                        onChanged: (value) {
                          _alternarStatusTarefa(
                              tarefas[index]['id'], value ?? false);
                        },
                      ),
                      title: Text('${tarefas[index]['descricao']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _excluirTarefa(tarefas[index]['id']);
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _excluirTodasTarefas();
                    },
                    child: Text('Excluir Todas Tarefas'),
                  ),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                TextEditingController _controller = TextEditingController();
                return AlertDialog(
                  title: Text('Adicionar Tarefa'),
                  content: TextField(
                    controller: _controller,
                    decoration: InputDecoration(labelText: 'Descrição'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        _salvarTarefa(_controller.text);
                        Navigator.pop(context);
                      },
                      child: Text('Adicionar'),
                    ),
                  ],
                );
              },
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
