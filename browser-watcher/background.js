// background.js

console.log("[Symbol Watcher] background.js loaded");

const notifiedSet = new Set();
const loggedSymbols = []; // now an ordered array (newest first)

function notifyLocalServer(symbol) {
  fetch("http://localhost:4113/notify", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ symbol }),
  }).catch((err) => {
    console.error("Failed to notify local server for", symbol, err);
  });
}

function updatePopup() {
  chrome.runtime.sendMessage({
    action: "updateLog",
    symbols: [...loggedSymbols], // maintain insertion order
  });
}

chrome.runtime.onConnect.addListener((port) => {
  if (port.name === "symbol-watcher-port") {
    port.onMessage.addListener((msg) => {
      if (msg.action === "requestLog") {
        port.postMessage({ symbols: [...loggedSymbols] });
      }
    });
  }
});

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === "logSymbols" && Array.isArray(request.symbols)) {
    let newNotified = false;
    request.symbols.forEach((sym) => {
      const s = sym.trim().toUpperCase();
      if (!notifiedSet.has(s)) {
        notifiedSet.add(s);
        loggedSymbols.unshift(s); // newest first
        notifyLocalServer(s);
        newNotified = true;
      }
    });

    if (newNotified) {
      updatePopup();
    }

    sendResponse({ status: "logged" });
  }

  if (request.action === "clearNotified") {
    notifiedSet.clear();
    loggedSymbols.length = 0;
    updatePopup();
    sendResponse({ status: "cleared" });
  }

  return true;
});
