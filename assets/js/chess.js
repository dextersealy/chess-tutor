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
    this.$board.on('click', this.handleClick);
    $('.cell').hover(e => this.showMoves(e), e => this.hideMoves(e));

    this.getMoveable();
  }

  showMoves(e) {
    const $piece = $(e.target);
    if (this.getSelected() || !$piece.hasClass('moveable')) {
      return;
    }

    $.get(`/chess/moves/${$piece.attr('id')}`).then(moves => {
      this.setValidMoves(moves);
    });
  }

  hideMoves() {
    if (!this.getSelected()) {
      this.setValidMoves([]);
    }
  }

  getSelected() {
    return $('.selected')[0];
  }
  getMoveable() {
    $.get('/chess/moves').then(resp => this.setMoveable(resp));
  }

  setMoveable(ids) {
    $('.moveable').toggleClass('moveable', false);
    ids.map(id => $(`#${id}`).toggleClass('moveable', true));
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

  isMoveInProgress() {
    return Boolean($('.selected').length);
  }

  validMove($piece) {
    return $piece.hasClass('valid');
  }

  startMove($piece) {
    $.get(`/chess/moves/${$piece.attr('id')}`).then(resp => {
      this.setValidMoves(resp);
      $('.selected').toggleClass('selected', false);
      $piece.toggleClass('selected', true);
    });
  }

  cancelMove() {
    $('.selected').toggleClass('selected', false);
    $('.valid').toggleClass('valid', false);
    this.setMoveable();
  }

  setValidMoves(moves) {
    $('.cell').toggleClass('valid', false);
    moves.forEach(coordinate => {
      $(`#${coordinate}`).toggleClass('valid', true);
    });
  }

  finishMove($to) {
    const $from = $('.selected')
    const from = $from.attr('id');
    const to = $to.attr('id');
    $.post('/chess/moves', { from, to }).then(resp => {
      $('.selected').toggleClass('selected', false);
      $('.valid').toggleClass('valid', false);
      this.setMoveable(resp);
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
