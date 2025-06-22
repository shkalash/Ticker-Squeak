importScripts("config.js");

// Now use:
const DEFAULT_NOTIFY_PORT = SymbolNotifierConfig.DEFAULT_NOTIFY_PORT;

let cachedPort; // Will store the port after the first load

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === "notifySymbol") {
    const { symbol } = message;

    // Function to send the notification
    const sendNotification = (port) => {
      const url = `http://127.0.0.1:${port}/notify`;
      fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ symbol }),
      }).catch(err => {
        console.warn("[Symbol Watcher] Background notify error:", err);
      });
    };

    if (cachedPort) {
      sendNotification(cachedPort);
    } else {
      chrome.storage.local.get(["notifyPort"], (result) => {
        cachedPort = result.notifyPort || DEFAULT_NOTIFY_PORT;
        sendNotification(cachedPort);
      });
    }
  }
});

chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && changes.notifyPort) {
    cachedPort = changes.notifyPort.newValue || DEFAULT_NOTIFY_PORT;
    console.log("[Symbol Watcher] Updated cached port:", cachedPort);
  }
});
