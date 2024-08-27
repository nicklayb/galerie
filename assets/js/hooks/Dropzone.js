export default {
  mounted() {
    this.el.addEventListener('ondragenter', this.handleDragEnter.bind(this))
    this.el.addEventListener('ondragleave', this.handleDragLeave.bind(this))
    this.el.addEventListener('ondragover', this.handleDragOver.bind(this))
    this.el.addEventListener('ondragstart', this.handleDragStart.bind(this))
    this.el.addEventListener('ondragend', this.handleDragEnd.bind(this))
  },
  handleDragEnter(e) {
    e.preventDefault()
    console.log({ e })
  },
  handleDragLeave(e) {
    e.preventDefault()
    console.log({ e })
  },
  handleDragOver(e) {
    e.preventDefault()
    console.log({ e })
  },
  handleDragStart(e) {
    e.preventDefault()
    console.log({ e })
  },
  handleDragEnd(e) {
    e.preventDefault()
    console.log({ e })
  }
}
