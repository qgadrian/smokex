// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"
import "bulma/css/bulma.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

import {EditorView, basicSetup} from "@codemirror/next/basic-setup"
import {EditorState} from "@codemirror/next/state"
import {tagExtension} from "@codemirror/next/state"
import {javascript} from "@codemirror/next/lang-javascript"

let Hooks = {}

Hooks.LoadPlanDefinitionContent = {
  content() { return this.el.dataset.content },
  targetElement() { return this.el },
  mounted() {
    let state = EditorState.create({
      doc:  this.content(),
      extensions: [
        basicSetup,
        EditorView.contentAttributes.of({ contenteditable: false }),
        tagExtension(Symbol("language"), javascript()),
      ]
    })

    let view = new EditorView({
      state,
      parent: this.targetElement(),
    })
  },
  updated() {
    let state = EditorState.create({
      doc:  this.content(),
      extensions: [
        basicSetup,
        EditorView.contentAttributes.of({ contenteditable: false }),
        tagExtension(Symbol("language"), javascript()),
      ]
    })

    let view = new EditorView({
      state,
      parent: this.targetElement(),
    })
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket
