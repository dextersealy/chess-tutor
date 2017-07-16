def diagonal_moves(row, col)
  moves = []
  for i in (1..7) do
    if row + i < 8
      moves << [row + i, col + i] if col + i < 8
      moves << [row + i, col - i] if col - i >= 0
    end
    if row - i >= 0
      moves << [row - i, col - i] if col - i >= 0
      moves << [row - i, col + i] if col + i < 8
    end
  end
  moves
end

def straight_line_moves(row, col)
  moves = []
  for i in (1..7) do
    moves << [row, col - i] if col - i >= 0
    moves << [row, col + i] if col + i < 8
    moves << [row - i, col] if row - i >= 0
    moves << [row + i, col] if row + i < 8
  end
  moves
end

def single_step_moves(row, col)
  moves = []
  moves << [row, col - 1] if col - 1 >= 0
  moves << [row, col + 1] if col + 1 < 8
  if row - 1 >= 0
    moves << [row - 1, col]
    moves << [row - 1, col - 1] if col - 1 >= 0
    moves << [row - 1, col + 1] if col + 1 < 8
  end
  if row + 1 < 8
    moves << [row + 1, col]
    moves << [row + 1, col - 1] if col - 1 >= 0
    moves << [row + 1, col + 1] if col + 1 < 8
  end
  moves
end
