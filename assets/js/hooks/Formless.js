export default {
  mounted() {
    this.el.addEventListener('change', event => {
      const eventName = this.el.dataset.event

      this.pushEvent(eventName, { value: event.target.value })
    })
  }
}
