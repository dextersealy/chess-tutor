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
    this.showMoves = this.showMoves.bind(this);
    this.hideMoves = this.hideMoves.bind(this);

    this.$board = $('.board')
    this.getMoves().then(() => this.showMoveable());

    $('#start-btn').click(() => this.startGame());
    $('.cell').hover(e => this.showMoves(e), e => this.hideMoves(e));
    $('.board').click(e => this.handleClick(e));
  }

  startGame() {
    $.post('/chess/new').then(pieces => {
      this.setBoard(pieces);
      this.getMoves().then(() => this.showMoveable());
    });
  }

  setBoard(pieces) {
    $('.cell').html(' ')
    $('.selected').toggleClass('selected');
    Object.keys(pieces).forEach(id => {
      $(`#${id}`).html(pieces[id])
    });
  }

  getMoves() {
    return $.get('/chess/moves').then(moves => {
      this.moves = moves;
    });
  }

  showMoveable() {
    $('.moveable').toggleClass('moveable', false);
    Object.keys(this.moves.current).forEach(id => {
      $(`#${id}`).toggleClass('moveable', true);
    });
  }

  showMoves(e) {
    const $piece = $(e.target);
    if (this.getSelected() || !$piece.hasClass('moveable')) {
      return;
    }
    this.showPieceMoves($piece);
  }

  hideMoves(e) {
    if (this.getSelected()) {
      return;
    }
    $('.cell').toggleClass('valid', false);
  }

  showPieceMoves($piece) {
    $('.cell').toggleClass('valid', false);
    this.getPieceMoves($piece).forEach(coordinate => {
      $(`#${coordinate}`).toggleClass('valid', true);
    });
  }

  getPieceMoves($piece) {
    return this.moves.current[$piece.attr('id')] || [];
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
    this.showPieceMoves($piece);
    $('.selected').toggleClass('selected', false);
    $piece.toggleClass('selected', true);
  }

  cancelMove() {
    $('.selected').toggleClass('selected', false);
    $('.valid').toggleClass('valid', false);
    this.setMoveable();
  }

  finishMove($to) {
    const $from = $('.selected')
    const from = $from.attr('id');
    const to = $to.attr('id');
    $.post('/chess/moves', { from, to }).then(moves => {
      this.moves = moves
      this.showMoveable();
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
