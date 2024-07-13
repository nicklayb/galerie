export default {
  mounted() {
    console.log("Infinitescroll Mounted")
    console.log(this.el)
    this.el.addEventListener('scroll', (e) => {
      console.log(e)
    })
  },
  handleScroll(event) {
    console.log(event)
  }
}
