// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

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

import cronstrue from 'cronstrue'
import Prism from "prismjs"

let Hooks = {}

Hooks.PrintCronHumanFriendly = {
  cronSentence() { return this.el.dataset.cronSentence },
  targetElement() { return this.el },
  mounted() {
    "..."
    //const cronSentence = this.cronSentence()
    //const humanFriendlyCron = cronstrue.toString(cronSentence)

    //this.targetElement().textContent = humanFriendlyCron
  }
}

Hooks.LoadPlanDefinitionContent = {
  content() { return this.el.dataset.content },
  allowEdit() { return this.el.dataset.allowEdit },
  targetElement() { return this.el },
  mounted() {
    let state = EditorState.create({
      doc:  this.content(),
      extensions: [
        basicSetup,
        EditorView.contentAttributes.of({ contenteditable: this.allowEdit() === "true" }),
        EditorView.theme({ content: {color: "white"} }),
        EditorView.updateListener.of(viewUpdate => {
          const planDefinitionContentElement = document.getElementById('plan-definition-content')

          if (planDefinitionContentElement) {
            const updatedText = viewUpdate.state.toJSON().doc
            planDefinitionContentElement.value = updatedText
          }
        }),
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
        EditorView.contentAttributes.of({ contenteditable: this.allowEdit() === "true" }),
        EditorView.theme({ content: {color: "white"} }),
        EditorView.updateListener.of(viewUpdate => {
          const planDefinitionContentElement = document.getElementById('plan-definition-content')

          if (planDefinitionContentElement) {
            const updatedText = viewUpdate.state.toJSON().doc
            planDefinitionContentElement.value = updatedText
          }
        }),
        tagExtension(Symbol("language"), javascript()),
      ]
    })

    let view = new EditorView({
      state,
      parent: this.targetElement(),
    })
  }
}

Hooks.LoadStripeButton = {
  buttonId() { return this.el.dataset.buttonId },
  userId() { return this.el.dataset.userId },
  userEmail() { return this.el.dataset.userEmail },
  successUrl() { return this.el.dataset.successUrl },
  cancelUrl() { return this.el.dataset.cancelUrl },
  priceId() { return this.el.dataset.priceId },
  mounted() {
    var checkoutButton = document.getElementById(`checkout-button-${this.priceId()}-${this.buttonId()}`);

    var _buttonId = this.buttonId();
    var _userId = this.userId();
    var _userEmail = this.userEmail();
    var _successUrl = this.successUrl();
    var _cancelUrl = this.cancelUrl();
    var _priceId = this.priceId();

    checkoutButton.addEventListener('click', function () {
      // When the customer clicks on the button, redirect
      // them to Checkout.
      if (!window.Stripe) { return };

      window.Stripe.redirectToCheckout({
        lineItems: [{price: _priceId, quantity: 1}],
        mode: 'subscription',
        clientReferenceId: _userId,
        customerEmail: _userEmail,
        // Do not rely on the redirect to the successUrl for fulfilling
        // purchases, customers may not always reach the success_url after
        // a successful payment.
        // Instead use one of the strategies described in
        // https://stripe.com/docs/payments/checkout/fulfillment
        successUrl: _successUrl,
        cancelUrl: _cancelUrl
      })
        .then(function (result) {
          if (result.error) {
            // If `redirectToCheckout` fails due to a browser or network
            // error, display the localized error message to your customer.
            var displayError = document.getElementById(`error-message-${_buttonId}`);
            displayError.textContent = result.error.message;
          }
        });
    });
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
NProgress.configure({showSpinner: false})
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket
