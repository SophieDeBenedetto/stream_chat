export default InfiniteScroll = {
  loadMore(entries) {
    const target = entries[0];
    if (target.isIntersecting) {
      this.pushEvent("load_more", {});
    }
  },
  mounted() {
    this.observer = new IntersectionObserver(
      (entries) => this.loadMore(entries),
      {
        root: null, // window by default
        rootMargin: "400px",
        threshold: 0.1,
      }
    );
    this.observer.observe(this.el);
  },
  destroyed() {
    this.observer.unobserve(this.el);
  }
};
