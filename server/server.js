const express = require("express");
const notifier = require("node-notifier");
const open = require("open");
const bodyParser = require("body-parser");

const app = express();
const PORT = 4113;

app.use((req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", "*"); // or restrict to 'chrome-extension://<ID>'
  res.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") {
    return res.sendStatus(200);
  }
  next();
});


app.use(bodyParser.json());

app.post("/notify", async (req, res) => {
  const { symbol } = req.body;
  if (!symbol || typeof symbol !== "string") {
    return res.status(400).send("Missing or invalid symbol");
  }

  const cleanSymbol = symbol.trim().toUpperCase();

  console.log(`[TickerSqueak] Received: ${cleanSymbol}`);

  notifier.notify({
    title: `New Symbol: ${cleanSymbol}`,
    message: `Click to open in TradingView`,
    open: `https://www.tradingview.com/symbols/${cleanSymbol}/`,
    timeout: 5
  });

  res.status(200).send("OK");
});

app.listen(PORT, () => {
  console.log(`[TickerSqueak] Listening on http://localhost:${PORT}`);
});
