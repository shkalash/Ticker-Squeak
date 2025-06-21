// content.js
console.log("[Symbol Watcher] content.js loaded");

let whitelist = [];
let isPageActive = true;
let notifyPort = "4113"; // Default

chrome.storage.local.get(["notifyPort"], (result) => {
  if (result.notifyPort) {
    notifyPort = result.notifyPort;
  }
});

window.addEventListener("beforeunload", () => {
  isPageActive = false;
});

function notifyServer(symbol) {
  if (!isPageActive) return;
  fetch(`http://localhost:${notifyPort}/notify`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ symbol }),
  }).catch(err => {
    console.warn("[Symbol Watcher] Notify server error:", err);
  });
}

function extractSymbolsFromText(text) {
  if (!text) return [];
  const matches = [...text.matchAll(/(?:\$|)[A-Z]{1,5}\b!?/g)];
  return matches.map(m => m[0].replace(/^\$/, "").replace(/!$/, ""));
}

function startDiscordObserver() {
  function observe(container) {
    console.log("[Symbol Watcher] Discord container found, starting observer.");
    const observer = new MutationObserver(mutations => {
      for (const mutation of mutations) {
        mutation.addedNodes.forEach(node => {
          if (!(node instanceof HTMLElement)) return;
          if (node.matches && node.matches("li[id^='chat-messages-']")) {
            const messageContent = node.querySelector('[id^="message-content-"]');
            if (messageContent) {
              const text = messageContent.innerText || messageContent.textContent;
              if (!text) return;
              const symbols = extractSymbolsFromText(text);
              symbols.forEach(sym => notifyServer(sym));
            }
          }
        });
      }
    });
    observer.observe(container, { childList: true, subtree: true });
  }

  function waitForMessagesContainer(retries = 40, delay = 500) {
    const container = document.querySelector('[data-list-id="chat-messages"]');
    if (container) {
      observe(container);
    } else if (retries > 0) {
      setTimeout(() => waitForMessagesContainer(retries - 1, delay), delay);
    } else {
      console.warn("[Symbol Watcher] Could not find Discord messages container.");
    }
  }

  waitForMessagesContainer();
}

function startOneOptionObserver() {
  console.log("[Symbol Watcher] Starting OneOption MutationObserver");
  const container = document.querySelector("#public > div > div.messages.main-chat.fixed-top");
  if (!container) {
    console.warn("[Symbol Watcher] OneOption messages container not found.");
    return;
  }

  const observer = new MutationObserver(() => {
    container.querySelectorAll("a[data-symbol]").forEach(el => {
      const sym = el.getAttribute("data-symbol");
      if (sym && /^[A-Z]{1,6}$/.test(sym)) {
        notifyServer(sym);
      }
    });
  });

  observer.observe(container, { childList: true, subtree: true });
}

function init() {
  try {
    chrome.storage.local.get(["whitelistedChannels"], (result) => {
      whitelist = result.whitelistedChannels || [];

      if (location.hostname.includes("discord.com")) {
        if (!whitelist.some(prefix => location.href.startsWith(prefix))) {
          console.log("[Symbol Watcher] Discord channel not whitelisted, skipping scan.");
          return;
        }
        startDiscordObserver();
      }

      if (location.hostname.includes("oneoption.com")) {
        startOneOptionObserver();
      }
    });
  } catch (err) {
    console.warn("[Symbol Watcher] Storage load failed:", err);
  }
}

init();
