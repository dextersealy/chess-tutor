class Flasher {
  constructor() {
    this.callback = this.callback.bind(this);
  }

  start($el, interval) {
    if (this.$el) {
      window.clearTimeout(this.id);
      this.$el = 0;
    }
    this.$el = $el;
    this.interval = interval;
    this.id = window.setTimeout(this.callback, 0);
  }

  stop() {
    if (this.$el) {
      this.$el.stop();
      this.$el.fadeIn(0);
      window.clearTimeout(this.id);
      this.$el = 0;
    }
  }

  isFlashing() {
    return Boolean(this.$el);
  }

  callback() {
    if (this.$el) {
      const $el = this.$el;
      const interval = this.interval;
      $el.fadeOut(interval, () => $el.fadeIn(interval));
      this.id = window.setTimeout(this.callback, interval);
    }
  }
}
