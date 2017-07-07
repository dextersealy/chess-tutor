class Board {
  constructor() {
    this.handleClick = this.handleClick.bind(this);
    this.highlightValidMoves = this.highlightValidMoves.bind(this);
    this.unhighlightValidMoves = this.unhighlightValidMoves.bind(this);

    $('#board').click(e => this.handleClick(e));
    $('.cell').hover(
      e => this.highlightValidMoves(e),
      e => this.unhighlightValidMoves(e)
    );
  }

  init() {
    this.getAllMoves().then(() => this.highlightPlayerMoves());
  }

  reset() {
    $.post('/chess/new').then(pieces => {
      this.setup(pieces);
      this.init();
    });
  }

  setup(pieces) {
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

  highlightPlayerMoves() {
    $('.selected').toggleClass('selected', false);
    $('.valid').toggleClass('valid', false);
    $('.threat').toggleClass('threat', false);
    $('.threatened').toggleClass('threatened', false);
    $('.moveable').toggleClass('moveable', false);
    Object.keys(this.moves.player).forEach(id => {
      $(`#${id}`).toggleClass('moveable', true);
    });
    this.highlightThreatenedPieces();
  }

  highlightThreatenedPieces() {
    $('.threatened').toggleClass('threatened', false);
    Object.keys(this.moves.opponent).forEach(id => {
      this.moves.opponent[id].forEach(pos => {
        const $cell = $(`#${pos}`);
        if ($cell.html() !== ' ') {
          $cell.toggleClass('threatened', true);
        }
      });
    });
  }

  unhightlightThreatendPieces() {
    $('.threatened').toggleClass('threatened', false);
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
      $to.html($from.html());
      $from.html(' ');
      this.saveMoves(moves);
      this.highlightPlayerMoves();
    });
  }
}
