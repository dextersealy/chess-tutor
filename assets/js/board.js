class Board {
  constructor() {
    this.handleClick = this.handleClick.bind(this);
    this.handleHoverIn = this.handleHoverIn.bind(this);
    this.handleHoverOut = this.handleHoverOut.bind(this);
    this.flasher = new Flasher;

    $('#board').click(e => this.handleClick(e));
    $('.cell').hover(e => this.handleHoverIn(e), e => this.handleHoverOut(e));
  }

  //  Start a new game

  init() {
    this.getBoard().then(board => this.startTurn(board));
  }

  reset() {
    $.post('/new').then(board => this.startTurn(board));
  }

  //  Turns

  startTurn(board) {
    this.getNextMoves().then(() => {
      this.whenDoneFlashing(() => {
        this.show(board);
        this.showNextMoves();
      });
    });
  }

  endTurn() {
    this.stopFlashing();
    this.hideMoves(false);
    this.hideThreats(false);
    this.hideNextMoves(false);
  }

  //  Display the board

  getBoard() {
    return $.get('/show');
  }

  show(board) {
    $('.selected').toggleClass('selected');
    this.showActive(board.active);
    this.showCaptured(board.captured);
  }

  showActive(pieces) {
    $('.cell').each(function() {
      const loc = $(this).attr('id');
      $(this).html(pieces[loc] || ' ');
    });
  }

  showCaptured(captured) {
    Object.keys(captured).forEach(color => {
      const pieces = captured[color];
      const $container = $(`.${color}-captured`);
      $container.toggleClass('empty', pieces.length === 0);
      $container.find('li').remove();
      pieces.forEach(piece => {
        $(`<li>${piece}</li>`).appendTo($container);
      });
    });
  }

  //  Retrieve the available moves

  getNextMoves() {
    return $.get('/moves').then(moves => {
      this.moves = moves;
    });
  }

  showNextMoves() {
    this.showMoveable();
    this.showThreatened();
  }

  hideNextMoves() {
    this.hideMoveable();
    this.hideThreatened();
  }

  //  Highlight the available moves

  showMoveable() {
    const board = this;
    $('.cell').each(function() {
      const loc = $(this).attr('id');
      const moves = board.moves.player[loc];
      $(this).toggleClass('moveable', Boolean(moves && moves.length));
    });
  }

  hideMoveable() {
    $('.moveable').toggleClass('moveable', false);
  }

  showThreatened() {
    const board = this;
    $('.cell').each(function() {
      const loc = $(this).attr('id');
      const threatened = Boolean(board.moves.threats[loc] &&
        board.isPlayerPiece($(this)));
      $(this).toggleClass('threatened', threatened);
    });
  }

  hideThreatened() {
    $('.cell').toggleClass('threatened', false);
  }

  // Hover actions

  handleHoverIn(e) {
    const $cell = $(e.target);
    this.showThreats($cell)
    if (!this.isPieceSelected()) {
      this.showMoves($cell);
    }
  }

  handleHoverOut() {
    this.hideThreats()
    if (!this.isPieceSelected()) {
      this.hideMoves();
    }
  }

  //  Highlight moves for a chess piece

  showMoves($piece) {
    if (this.isMoveable($piece)) {
      this.hideMoves();
      this.getMoves($piece).forEach(loc => {
        const $cell = $(`#${loc}`);
        $cell.toggleClass('valid', true);
        $cell.toggleClass('unsafe', Boolean(this.moves.threats[loc]));
      });
    }
  }

  hideMoves() {
    $('.cell').toggleClass('valid', false);
    $('.cell').toggleClass('unsafe', false);
  }

  getMoves($piece) {
    return this.moves.player[this.getLoc($piece)] || [];
  }

  //  Highlight threatenING pieces

  showThreats($cell) {
    this.hideThreats();
    if (this.hasThreat($cell)) {
      const threats = this.moves.threats[this.getLoc($cell)];
      if (threats) {
        threats.forEach(loc => $(` #${loc}`).toggleClass('threat', true));
        this.flash($('.threat'));
      }
    }
  }

  hideThreats() {
    this.stopFlashing();
    $('.cell').toggleClass('threat', false);
  }

  hasThreat($cell) {
    return this.isThreatened($cell) || (this.isPieceSelected() &&
      this.isUnsafe($cell));
  }

  //  Move actions

  handleClick(e) {
    const $cell = $(e.target);
    if (this.getLoc($cell) === this.getSelectedLoc()) {
      this.cancelMove();
    } else if (this.isMoveable($cell)) {
      this.startMove($cell);
    } else if (this.isValidMove($cell)) {
      this.finishMove($cell).then(() => this.makeMove());
    }
  }

  startMove($piece) {
    $('.selected').toggleClass('selected', false);
    $piece.toggleClass('selected', true);
    this.showMoves($piece);
  }

  cancelMove() {
    $('.selected').toggleClass('selected', false);
    $('.valid').toggleClass('valid', false);
  }

  finishMove($to) {
    const $from = $('.selected')
    const from = $from.attr('id');
    const to = $to.attr('id');
    return $.post('/move', { from, to }).then(board => {
      this.show(board);
    });
  }

  makeMove() {
    this.endTurn();
    $.get('/move').then(move => {
      this.showMove(move.from, move.to, move.board);
    });
  }

  showMove(from, to, board) {
    const interval = Board.FLASH_INTERVAL / 2;
    const $from = $(`#${from}`);
    const $to = $(`#${to}`);

    this.flash($from, interval);
    window.setTimeout(($from, $to) => {
      $to.html($from.html());
      $from.html(' ');
      this.flash($to, interval / 2);
      window.setTimeout(() => this.stopFlashing(), interval * 4)
      this.startTurn(board);
    }, interval * 4, $from, $to);
  }

  // Flashing

  flash($el, interval = Board.FLASH_INTERVAL) {
    this.flasher.start($el, interval);
  }

  stopFlashing() {
    this.flasher.stop();
  }

  whenDoneFlashing(func) {
    if (this.flasher.isFlashing()) {
      window.setTimeout(() => this.whenDoneFlashing(func), this.FLASH_INTERVAL);
    } else {
      func();
    }
  }

  //  Utility functions

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

Board.FLASH_INTERVAL = 500;
