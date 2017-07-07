class Board {
  constructor() {
    this.handleClick = this.handleClick.bind(this);
    this.handleHoverIn = this.handleHoverIn.bind(this);
    this.handleHoverOut = this.handleHoverOut.bind(this);

    $('#board').click(e => this.handleClick(e));
    $('.cell').hover(e => this.handleHoverIn(e), e => this.handleHoverOut(e));
  }

  //  Start a new game

  reset() {
    $.post('/chess/new').then(pieces => {
      this.setup(pieces);
      this.init();
    });
  }

  //  Arrange the pieces on the board

  setup(pieces) {
    $('.cell').html(' ')
    $('.selected').toggleClass('selected');
    Object.keys(pieces).forEach(loc => {
      $(`#${loc}`).html(pieces[loc])
    });
  }

  //  Display the board status

  init() {
    this.getNextMoves().then(() => this.highlightNextMoves());
  }

  //  Retrieve the available moves

  getNextMoves() {
    return $.get('/chess/moves').then(moves => {
      this.moves = moves;
    });
  }

  //  Highlight the available moves

  highlightNextMoves() {
    $('.selected').toggleClass('selected', false);
    $('.valid').toggleClass('valid', false);
    $('.threat').toggleClass('threat', false);
    this.highlightMoveablePieces();
    this.highlightThreatenedPieces();
  }

  highlightMoveablePieces() {
    $('.moveable').toggleClass('moveable', false);
    Object.keys(this.moves.player).forEach(loc => {
      const moveable = Boolean(this.moves.player[loc].length);
      $(`#${loc}`).toggleClass('moveable', moveable);
    });
  }

  highlightThreatenedPieces() {
    $('.threatened').toggleClass('threatened', false);
    Object.keys(this.moves.threats).forEach(loc => {
      const $cell = $(`#${loc}`);
      if (this.isPlayerPiece($cell)) {
        $cell.toggleClass('threatened', true);
      }
    });
  }

  // Hover actions

  handleHoverIn(e) {
    const $cell = $(e.target);
    this.highlightThreats($cell)
    if (!this.isPieceSelected()) {
      this.highlightMoves($cell);
    }
  }

  handleHoverOut() {
    this.unhighlightThreats()
    if (!this.isPieceSelected()) {
      this.unhighlightMoves();
    }
  }

  //  Highlight available moves

  highlightMoves($piece) {
    if (this.isMoveable($piece)) {
      $('.cell').toggleClass('valid', false);
      $('.cell').toggleClass('unsafe', false);
      this.getMoves($piece).forEach(loc => {
        const $cell = $(`#${loc}`);
        $cell.toggleClass('valid', true);
        $cell.toggleClass('unsafe', Boolean(this.moves.threats[loc]));
      });
    }
  }

  getMoves($piece) {
    return this.moves.player[this.getLoc($piece)] || [];
  }

  unhighlightMoves() {
    $('.cell').toggleClass('valid', false);
  }

  //  Highlight threatenING pieces

  highlightThreats($cell) {
    if (this.hasThreat($cell)) {
      $('.cell').toggleClass('threat', false);
      const threats = this.moves.threats[this.getLoc($cell)];
      threats && threats.forEach(loc => {
        $(`#${loc}`).toggleClass('threat', true);
      });
    }
  }

  hasThreat($cell) {
    return this.isThreatened($cell) || (this.isPieceSelected() &&
      this.isUnsafe($cell));
  }

  unhighlightThreats() {
    $('.cell').toggleClass('threat', false);
  }

  //  Move actions

  handleClick(e) {
    const $cell = $(e.target);
    if (this.getLoc($cell) === this.getSelectedLoc()) {
      this.cancelMove();
    } else if (canMove($cell)) {
      this.startMove($cell);
    } else if (this.isValidMove($cell)) {
      this.finishMove($cell);
    }
  }

  startMove($piece) {
    $('.selected').toggleClass('selected', false);
    $piece.toggleClass('selected', true);
    this.highlightMoves($piece);
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
      this.moves = moves;
      this.highlightNextMoves();
    });
  }

  getLoc($cell) {
    return $cell.attr('id');
  }

  getSelectedLoc() {
    return $('.selected').attr('id');
  }

  isPieceSelected() {
    return $('.selected').length > 0;
  }

  isPlayerPiece($cell) {
    return Boolean(this.moves.player[this.getLoc($cell)]);
  }

  isUnsafe($cell) {
    return $cell.hasClass('unsafe');
  }

  isThreatened($cell) {
    return $cell.hasClass('threatened');
  }

  isMoveable($cell) {
    return $cell.hasClass('moveable');
  }

  isValidMove($cell) {
    return $cell.hasClass('valid');
  }

}
