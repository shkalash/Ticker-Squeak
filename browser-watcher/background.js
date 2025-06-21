chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === "notifySymbol") {
    const { symbol } = message;
    fetch("http://127.0.0.1:4113/notify", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ symbol }),
    }).catch(err => {
      console.warn("[Symbol Watcher] Background notify error:", err);
    });
  }
});
