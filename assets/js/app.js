class App {
  constructor() {
    $('#start-btn').click(() => this.restart());
    this.board = new Board;
  }

  start() {
    this.board.init();
  }

  restart() {
    this.board.reset();
  }
}
