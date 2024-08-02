const LEFT_VALUE_SELECTOR = ".left-value"
const RIGHT_VALUE_SELECTOR = ".right-value"
const LEFT_INPUT_SELECTOR = ".left-input"
const RIGHT_INPUT_SELECTOR = ".right-input"

const DEFAULT_LEFT_EVENT = "slide-left"
const DEFAULT_RIGHT_EVENT = "slide-right"

export default {
  mounted() {
    this.leftValue = this.el.querySelector(LEFT_VALUE_SELECTOR)
    this.rightValue = this.el.querySelector(RIGHT_VALUE_SELECTOR)
    this.leftInput = this.el.querySelector(LEFT_INPUT_SELECTOR)
    this.rightInput = this.el.querySelector(RIGHT_INPUT_SELECTOR)

    this.leftEvent = this.el.dataset.leftEvent || DEFAULT_LEFT_EVENT
    this.rightEvent = this.el.dataset.rightEvent || DEFAULT_RIGHT_EVENT

    this.leftInput.addEventListener("input", this.handleLeftInput.bind(this))
    this.rightInput.addEventListener("input", this.handleRightInput.bind(this))
  },
  handleLeftInput(event) {
    this.pushEvent(this.leftEvent, { value: event.target.value })
  },
  handleRightInput(event) {
    this.pushEvent(this.rightEvent, { value: event.target.value })
  }
}
