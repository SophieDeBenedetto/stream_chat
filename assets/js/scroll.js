export default ScrollDown = {
  mounted() {
    this.el.scrollTop = this.el.scrollHeight
  },

  updated() {
    if (this.el.dataset.scrolledToTop == "false") {
      this.el.scrollTop = this.el.scrollHeight
    }
  }
}
