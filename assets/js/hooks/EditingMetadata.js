import { ESCAPE } from './keys'
export default {
  mounted() {
    this.componentId = this.el.dataset.myself
    this.el.focus()
    this.el.addEventListener('blur', this.handleBlur.bind(this))
    this.el.addEventListener('keyup', event => {
      if (event.key == ESCAPE) {
        this.handleBlur(event)
      }
    })
  },
  handleBlur(_event) {
    this.pushEventTo(this.componentId, "viewer:metadata:cancel")
  }
}
