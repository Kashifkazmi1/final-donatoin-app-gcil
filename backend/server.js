// Minimal Stripe Terminal backend for the donation app.
//
// Setup:
//   1. cd backend && npm install
//   2. Set your secret key:  export STRIPE_SECRET_KEY=sk_test_...
//   3. node server.js
//
// The Flutter app calls:
//   POST /connection_token       -> { secret }
//   POST /create_payment_intent  -> { client_secret }   body: { amount, currency }

const express = require("express");
const app = express();
app.use(express.json());

const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);

// Terminal SDK authentication
app.post("/connection_token", async (_req, res) => {
  try {
    const token = await stripe.terminal.connectionTokens.create();
    res.json({ secret: token.secret });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create a PaymentIntent for an in-person (card_present) donation
app.post("/create_payment_intent", async (req, res) => {
  try {
    const { amount, currency } = req.body;

    // Basic server-side validation — never trust the client amount blindly.
    if (!Number.isInteger(amount) || amount < 100 || amount > 1000000) {
      return res.status(400).json({ error: "Invalid amount" });
    }

    const intent = await stripe.paymentIntents.create({
      amount, // in cents
      currency: currency || "usd",
      payment_method_types: ["card_present"],
      capture_method: "automatic",
      description: "Donation",
    });

    res.json({ client_secret: intent.client_secret, id: intent.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 4242;
app.listen(PORT, () =>
  console.log(`Donation backend running on http://localhost:${PORT}`)
);
