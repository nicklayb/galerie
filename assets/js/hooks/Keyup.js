export default {
  mounted() {
    const eventName = this.el.dataset.onWindowKeyup
    console.log(document.activeElement)
    document.activeElement.blur()
    window.addEventListener('keyup', (event) => {
      console.log(document.activeElement)
      if (event.target.localName === "body") {
        this.pushEvent(eventName, { key: event.key })
      }
    })
  }
}
