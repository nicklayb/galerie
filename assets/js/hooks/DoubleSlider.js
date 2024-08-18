const LEFT_INPUT_SELECTOR = ".left-input"
const RIGHT_INPUT_SELECTOR = ".right-input"
const LEFT = "left"
const RIGHT = "right"

const DEFAULT_EVENT = "slider"

export default {
  mounted() {
    this.max = this.el.dataset.max
    this.min = this.el.dataset.min
    this.minimumGap = this.el.dataset.minimumGap || 0

    this.leftInput = this.el.querySelector(LEFT_INPUT_SELECTOR)
    this.rightInput = this.el.querySelector(RIGHT_INPUT_SELECTOR)

    this.phoenixEvent = this.el.dataset.event || DEFAULT_EVENT

    this.leftInput.addEventListener("input", this.handleLeftInput.bind(this))
    this.rightInput.addEventListener("input", this.handleRightInput.bind(this))
  },
  getLeftValue() {
    return parseInt(this.leftInput.value)
  },
  getRightValue() {
    return parseInt(this.rightInput.value)
  },
  handleLeftInput(event) {
    const newValue = parseInt(event.target.value)
    if (this.overflows(newValue, this.getRightValue())) {
      const limitValue = this.getRightValue() - this.minimumGap
      event.target.value = limitValue
      if (event.target.value !== limitValue) {
        this.pushSliderEvent(LEFT, limitValue)
      }
      event.target.value = limitValue
    } else {
      this.pushSliderEvent(LEFT, newValue)
    }
  },
  handleRightInput(event) {
    const newValue = parseInt(event.target.value)
    if (this.overflows(this.getLeftValue(), newValue)) {
      const limitValue = this.getLeftValue() + this.minimumGap
      if (event.target.value !== limitValue) {
        this.pushSliderEvent(RIGHT, limitValue)
      }
      event.target.value = limitValue
    } else {
      this.pushSliderEvent(RIGHT, newValue)
    }
  },
  overflows(leftValue, rightValue) {
    return rightValue - leftValue <= this.minimumGap
  },
  pushSliderEvent(boundary, value) {
    this.pushEvent(this.phoenixEvent, { value, boundary })
  }
}
