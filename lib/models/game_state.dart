class GameState {
  final List<List<int?>> board;
  final List<List<bool?>> isFirstPlayerCell; // true для первого игрока, false для второго
  final bool isFirstPlayerTurn;
  final bool gameOver;
  final String? winner;
  final Set<int> availableNumbersPlayer1;
  final Set<int> availableNumbersPlayer2;

  GameState({
    List<List<int?>>? board,
    List<List<bool?>>? isFirstPlayerCell,
    this.isFirstPlayerTurn = true,
    this.gameOver = false,
    this.winner,
    Set<int>? availableNumbersPlayer1,
    Set<int>? availableNumbersPlayer2,
  }) : board = board ?? List.generate(3, (_) => List.filled(3, null)),
       isFirstPlayerCell = isFirstPlayerCell ?? List.generate(3, (_) => List.filled(3, null)),
       availableNumbersPlayer1 = availableNumbersPlayer1 ?? {1, 2, 3, 4, 5, 6, 7, 8, 9},
       availableNumbersPlayer2 = availableNumbersPlayer2 ?? {1, 2, 3, 4, 5, 6, 7, 8, 9};

  GameState copyWith({
    List<List<int?>>? board,
    List<List<bool?>>? isFirstPlayerCell,
    bool? isFirstPlayerTurn,
    bool? gameOver,
    String? winner,
    Set<int>? availableNumbersPlayer1,
    Set<int>? availableNumbersPlayer2,
  }) {
    return GameState(
      board: board ?? List.from(this.board.map((row) => List.from(row))),
      isFirstPlayerCell: isFirstPlayerCell ?? List.from(this.isFirstPlayerCell.map((row) => List.from(row))),
      isFirstPlayerTurn: isFirstPlayerTurn ?? this.isFirstPlayerTurn,
      gameOver: gameOver ?? this.gameOver,
      winner: winner ?? this.winner,
      availableNumbersPlayer1: availableNumbersPlayer1 ?? Set.from(this.availableNumbersPlayer1),
      availableNumbersPlayer2: availableNumbersPlayer2 ?? Set.from(this.availableNumbersPlayer2),
    );
  }

  bool isValidMove(int row, int col, int number) {
    if (row < 0 || row >= 3 || col < 0 || col >= 3) return false;
    
    final availableNumbers = isFirstPlayerTurn ? availableNumbersPlayer1 : availableNumbersPlayer2;
    if (!availableNumbers.contains(number)) return false;
    
    final currentValue = board[row][col];
    return currentValue == null || currentValue < number;
  }

  bool checkWin() {
    // Проверка для обоих игроков
    bool checkWinForPlayer(bool isFirstPlayer) {
      // Проверка строк
      for (var row = 0; row < 3; row++) {
        if (isFirstPlayerCell[row].every((cell) => cell == isFirstPlayer)) {
          return true;
        }
      }

      // Проверка столбцов
      for (var col = 0; col < 3; col++) {
        if (isFirstPlayerCell.every((row) => row[col] == isFirstPlayer)) {
          return true;
        }
      }

      // Проверка главной диагонали
      if (isFirstPlayerCell[0][0] == isFirstPlayer &&
          isFirstPlayerCell[1][1] == isFirstPlayer &&
          isFirstPlayerCell[2][2] == isFirstPlayer) {
        return true;
      }

      // Проверка побочной диагонали
      if (isFirstPlayerCell[0][2] == isFirstPlayer &&
          isFirstPlayerCell[1][1] == isFirstPlayer &&
          isFirstPlayerCell[2][0] == isFirstPlayer) {
        return true;
      }

      return false;
    }

    // Проверяем победу для текущего игрока
    return checkWinForPlayer(isFirstPlayerTurn);
  }
}
