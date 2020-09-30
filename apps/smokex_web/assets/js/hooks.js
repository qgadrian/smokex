import {EditorView, basicSetup} from "@codemirror/next/basic-setup"
import {EditorState} from "@codemirror/next/state"
import {tagExtension} from "@codemirror/next/state"
import {javascript} from "@codemirror/next/lang-javascript"
import {keymap} from "@codemirror/next/view"
import { defaultKeymap, indentMore, indentLess } from "@codemirror/next/commands";

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
        keymap([
          ...defaultKeymap,
          {
            key: "Tab",
            preventDefault: true,
            run: indentMore,
          },
          {
            key: "Shift-Tab",
            preventDefault: true,
            run: indentLess,
          },
        ]),
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
        keymap([
          ...defaultKeymap,
          {
            key: "Tab",
            preventDefault: true,
            run: indentMore,
          },
          {
            key: "Shift-Tab",
            preventDefault: true,
            run: indentLess,
          },
        ]),
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
  maybeLoadStripeScript() {
    if(!window.Stripe) {
      const publishableApiKey = this.el.dataset.publishableApiKey;
      const stripeJs = document.createElement('script');
      stripeJs.src = 'https://js.stripe.com/v3/';
      stripeJs.async = true;
      stripeJs.onload = () => {
        window.Stripe = Stripe(publishableApiKey);
      };
      document.body && document.body.appendChild(stripeJs)
    }
  },
  mounted() {
    var checkoutButton = document.getElementById(`checkout-button-${this.priceId()}-${this.buttonId()}`);

    var _buttonId = this.buttonId();
    var _userId = this.userId();
    var _userEmail = this.userEmail();
    var _successUrl = this.successUrl();
    var _cancelUrl = this.cancelUrl();
    var _priceId = this.priceId();

    this.maybeLoadStripeScript();

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


export { Hooks };
