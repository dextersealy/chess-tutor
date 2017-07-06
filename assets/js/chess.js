const csrf_token = $('meta[name="authenticity_token"]').attr('content');
$.ajaxPrefilter(function(options, originalOptions, jqXHR){
    if (options.type.toLowerCase() === 'post') {
        options.data = options.data || '';
        options.data += options.data ? '&' : '';
        options.data += 'authenticity_token=' + csrf_token;
    }
});

$(() => {
  new Board;
})

class Board {
  constructor() {
    this.handleClick = this.handleClick.bind(this);
    this.highlightValidMoves = this.highlightValidMoves.bind(this);
    this.unhighlightValidMoves = this.unhighlightValidMoves.bind(this);

    this.$board = $('.board')
    this.getAllMoves().then(() => this.highlightMoveablePieces());

    $('#start-btn').click(() => this.startGame());
    $('.board').click(e => this.handleClick(e));
    $('.cell').hover(
      e => this.highlightValidMoves(e),
      e => this.unhighlightValidMoves(e)
    );
  }

  startGame() {
    $.post('/chess/new').then(pieces => {
      this.setupBoard(pieces);
      this.getAllMoves().then(() => this.highlightMoveablePieces());
    });
  }

  setupBoard(pieces) {
    $('.cell').html(' ')
    $('.selected').toggleClass('selected');
    Object.keys(pieces).forEach(id => {
      $(`#${id}`).html(pieces[id])
    });
  }

  getAllMoves() {
    return $.get('/chess/moves').then(moves => {
      this.saveMoves(moves);
    });
  }

  saveMoves(moves) {
    this.moves = moves;
  }

  highlightMoveablePieces() {
    $('.moveable').toggleClass('moveable', false);
    Object.keys(this.moves.player).forEach(id => {
      $(`#${id}`).toggleClass('moveable', true);
    });
  }

  highlightValidMoves(e) {
    const $cell = $(e.target);
    if (this.getSelected()) {
      if ($cell.hasClass('unsafe')) {
        this.highlightThreatMoves($cell)
      }
    } else if ($cell.hasClass('moveable')) {
      this.tagValidMoves($cell);
    }
  }

  tagValidMoves($piece) {
    $('.cell').toggleClass('valid', false);
    this.getPieceMoves($piece).forEach(coordinate => {
      const $cell = $(`#${coordinate}`);
      const unsafe = Boolean(this.moves.threats[coordinate]);
      $cell.toggleClass('valid', true);
      $cell.toggleClass('unsafe', unsafe);
    });
  }

  unhighlightValidMoves() {
    if (this.getSelected()) {
      this.unhighlightThreatMoves()
    } else {
      $('.cell').toggleClass('valid', false);
    }
  }

  highlightThreatMoves($cell) {
    $('.cell').toggleClass('threat', false);
    const id = $cell.attr('id');
    const threats = this.moves.threats[id];
    threats && threats.forEach(pos => {
      const $cell = $(`#${pos}`);
      $cell.toggleClass('threat', true);
    });
  }

  unhighlightThreatMoves() {
    $('.cell').toggleClass('threat', false);
  }

  getPieceMoves($piece) {
    return this.moves.player[$piece.attr('id')] || [];
  }

  getSelected() {
    return $('.selected')[0];
  }

  handleClick(e) {
    const $piece = $(e.target);
    if ($piece.attr('id') === $('.selected').attr('id')) {
      this.cancelMove();
    } else if (canMove($piece)) {
      this.startMove($piece);
    } else if (this.validMove($piece)) {
      this.finishMove($piece);
    }
  }

  validMove($piece) {
    return $piece.hasClass('valid');
  }

  startMove($piece) {
    $('.selected').toggleClass('selected', false);
    $piece.toggleClass('selected', true);
    this.tagValidMoves($piece);
  }

  cancelMove() {
    $('.selected').toggleClass('selected', false);
    $('.valid').toggleClass('valid', false);
  }

  finishMove($to) {
    const $from = $('.selected')
    const from = $from.attr('id');
    const to = $to.attr('id');
    $.post('/chess/moves', { from, to }).then(moves => {
      this.saveMoves(moves);
      this.highlightMoveablePieces();
      $('.selected').toggleClass('selected', false);
      $('.valid').toggleClass('valid', false);
      $to.html($from.html());
      $from.html(' ');
    });
  }
}

function getPiece($cell) {
  return $cell.html();
}

function canMove($cell) {
  return $cell.hasClass('moveable');
}
