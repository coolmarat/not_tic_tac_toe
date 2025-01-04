import 'package:flutter/material.dart';
import 'models/game_state.dart';
import 'dart:math'; // добавляем импорт для использования math.min

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '1Числовые крестики-нолики',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState gameState;
  int? selectedNumber;

  @override
  void initState() {
    super.initState();
    gameState = GameState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showGameRules();
    });
  }

  void showGameRules() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Правила игры'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Добро пожаловать в игру "Числовые крестики-нолики"!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Правила игры:'),
                SizedBox(height: 8),
                
                Text('1. Каждый ход состоит из двух действий:'),
                Text('   • Выбор числа от 1 до 9'),
                Text('   • Размещение числа в клетке поля'),
                SizedBox(height: 8),
                Text('2. Особенности хода:'),
                Text('   • Можно ставить число в пустую клетку'),
                Text('   • Можно ставить число поверх меньшего числа'),
                Text('   • Каждое число можно использовать только один раз'),
                SizedBox(height: 8),
                Text('3. Цель игры:'),
                Text('   Собрать три своих числа в ряд:'),
                Text('   • по горизонтали, или'),
                Text('   • по вертикали, или'),
                Text('   • по диагонали'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Начать игру'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _resetGame() {
    setState(() {
      gameState = GameState();
      selectedNumber = null;
    });
    showGameRules();
  }

  void _onNumberSelected(int number) {
    setState(() {
      selectedNumber = number;
    });
  }

  void _onCellTapped(int row, int col) {
    if (selectedNumber == null || gameState.gameOver) return;

    if (gameState.isValidMove(row, col, selectedNumber!)) {
      setState(() {
        final newBoard = List<List<int?>>.from(
          gameState.board.map((row) => List<int?>.from(row)),
        );
        final newIsFirstPlayerCell = List<List<bool?>>.from(
          gameState.isFirstPlayerCell.map((row) => List<bool?>.from(row)),
        );
        
        newBoard[row][col] = selectedNumber;
        newIsFirstPlayerCell[row][col] = gameState.isFirstPlayerTurn;
        
        final newAvailableNumbersPlayer1 = Set<int>.from(gameState.availableNumbersPlayer1);
        final newAvailableNumbersPlayer2 = Set<int>.from(gameState.availableNumbersPlayer2);
        
        if (gameState.isFirstPlayerTurn) {
          newAvailableNumbersPlayer1.remove(selectedNumber);
        } else {
          newAvailableNumbersPlayer2.remove(selectedNumber);
        }
        
        // Создаем временное состояние для проверки победы
        final tempState = gameState.copyWith(
          board: newBoard,
          isFirstPlayerCell: newIsFirstPlayerCell,
        );

        final hasWon = tempState.checkWin();
        
        gameState = gameState.copyWith(
          board: newBoard,
          isFirstPlayerCell: newIsFirstPlayerCell,
          isFirstPlayerTurn: !gameState.isFirstPlayerTurn,
          availableNumbersPlayer1: newAvailableNumbersPlayer1,
          availableNumbersPlayer2: newAvailableNumbersPlayer2,
          gameOver: hasWon,
          winner: hasWon ? (gameState.isFirstPlayerTurn ? 'Игрок 1' : 'Игрок 2') : null,
        );

        if (hasWon) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Игра окончена!'),
                content: Text('${gameState.winner} победил!'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Новая игра'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        gameState = GameState();
                        selectedNumber = null;
                      });
                    },
                  ),
                ],
              );
            },
          );
        }

        selectedNumber = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Недопустимый ход! Выберите большее число или пустую клетку.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildNumberButton(int number, Color color, bool isAvailable, bool isCurrentPlayer) {
    Color getButtonColor() {
      // Если число недоступно (использовано) - кнопка серая
      if (!isAvailable) {
        return Colors.grey.shade300;
      }
      
      // Если это выбранное число активного игрока
      if (selectedNumber == number && isCurrentPlayer) {
        return Colors.grey;
      }
      
      // Для активного игрока - яркий цвет
      if (isCurrentPlayer) {
        return color;
      }
      
      // Для неактивного игрока - светлый оттенок его цвета (если число доступно)
      return color == Colors.blue 
          ? Colors.blue.shade200  // Светло-голубой для доступных чисел первого игрока
          : Colors.red.shade200;  // Светло-розовый для доступных чисел второго игрока
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: getButtonColor(),
          minimumSize: const Size(50, 50),
          // Отключаем эффект затемнения при disabled состоянии
          disabledBackgroundColor: getButtonColor(),
          elevation: (isAvailable && isCurrentPlayer) ? 4 : 0, // Добавляем тень только активным кнопкам
        ),
        // Активируем нажатие только для доступных чисел активного игрока
        onPressed: (isAvailable && isCurrentPlayer) 
            ? () => _onNumberSelected(number) 
            : null,
        child: Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerNumbers(bool isFirstPlayer) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(9, (index) => index + 1)
          .map((n) => _buildNumberButton(
                n,
                isFirstPlayer ? Colors.blue : Colors.red,
                (isFirstPlayer 
                    ? gameState.availableNumbersPlayer1 
                    : gameState.availableNumbersPlayer2).contains(n),
                gameState.isFirstPlayerTurn == isFirstPlayer,
              ))
          .toList(),
    );
  }

  Widget _buildCell(int row, int col) {
    final value = gameState.board[row][col];
    final isFirstPlayer = gameState.isFirstPlayerCell[row][col];
    return GestureDetector(
      onTap: () => _onCellTapped(row, col),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
        ),
        child: Center(
          child: Text(
            value?.toString() ?? '',
            style: TextStyle(
              fontSize: 40,
              color: value == null ? Colors.black 
                : isFirstPlayer == true ? Colors.blue 
                : Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('1Числовые крестики-нолики'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: showGameRules,
            tooltip: 'Правила игры',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: 'Новая игра',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Рассчитываем размер игрового поля
          final availableHeight = constraints.maxHeight;
          final playerSectionHeight = availableHeight * 0.25; // 25% высоты для каждого игрока
          final gameFieldSize = min(
            availableHeight - (playerSectionHeight * 2), // Оставшаяся высота
            constraints.maxWidth - 40, // Ширина минус отступы
          );

          return Column(
            children: [
              // Числа второго игрока (красные)
              SizedBox(
                height: playerSectionHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Игрок 2 (красный)${!gameState.isFirstPlayerTurn ? " - Ваш ход" : ""}',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.red,
                        fontWeight: !gameState.isFirstPlayerTurn ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPlayerNumbers(false),
                  ],
                ),
              ),
              // Игровое поле
              SizedBox(
                width: gameFieldSize,
                height: gameFieldSize,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    final row = index ~/ 3;
                    final col = index % 3;
                    return _buildCell(row, col);
                  },
                ),
              ),
              // Числа первого игрока (синие)
              SizedBox(
                height: playerSectionHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Игрок 1 (синий)${gameState.isFirstPlayerTurn ? " - Ваш ход" : ""}',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.blue,
                        fontWeight: gameState.isFirstPlayerTurn ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPlayerNumbers(true),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
