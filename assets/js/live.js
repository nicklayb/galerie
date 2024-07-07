import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import Hooks from "./hooks"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  params: {
    _csrf_token: csrfToken
  },
  hooks: Hooks,
  metadata: {
    click: (e, _el) => ({
      ctrl_key: e.ctrlKey,
      meta_key: e.metaKey,
      shift_key: e.shiftKey
    }),
    keydown: (e, _el) => ({
      key: e.key,
      ctrl_key: e.ctrlKey,
      meta_key: e.metaKey,
      shift_key: e.shiftKey
    }),
  }
})

liveSocket.connect()

window.liveSocket = liveSocket
