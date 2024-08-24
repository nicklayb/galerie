export default {
  mounted() {
    const eventName = this.el.dataset.onWindowKeyup
    window.addEventListener('keyup', (event) => {
      if (event.target.localName === "body") {
        this.pushEvent(eventName, { key: event.key })
      }
    })
  }
}
