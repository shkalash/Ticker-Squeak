console.log("[Symbol Watcher] content.js loaded");

let whitelist = [];
let isPageActive = true;

window.addEventListener("beforeunload", () => {
  isPageActive = false;
});

function notifyServer(symbol, highPriority = false) {
  chrome.runtime.sendMessage({
    type: "notifySymbol",
    symbol,
    highPriority
  });
}

/**
 * Parses text to find stock symbols based on strict word boundaries.
 * A symbol is a word of 1-5 capital letters, optionally prefixed with '$'
 * and/or postfixed with '!', surrounded by spaces or string boundaries.
 * @param {string} text The text to parse.
 * @returns {Array<{symbol: string, highPriority: boolean}>} An array of found symbols.
 */
function parseSymbols(text) {
    if (!text) return [];

    // Regex Explanation:
    // (?:^|\s)     - Start of string or a whitespace (ensures it's a whole word). Non-capturing.
    // (             - Start of the main capturing group for the symbol string itself (e.g., "$AAPL!").
    //   \$?         - An optional literal dollar sign prefix.
    //   [A-Z]{1,5}  - 1 to 5 uppercase letters. This enforces the "no other characters" rule.
    //   !?          - An optional literal exclamation mark postfix.
    // )             - End of the main capturing group.
    // (?=\s|$)     - A positive lookahead asserting the symbol is followed by a
    //               whitespace or the end of the string (without including it in the match).
    const symbolRegex = /(?:^|\s)(\$?[A-Z]{1,5}!?)(?=\s|$)/g;

    const matches = [...text.matchAll(symbolRegex)];

    // The full string we care about (e.g., "$AAPL!") is in the first captured group.
    return matches.map(match => {
        const rawMatch = match[1];
        const highPriority = rawMatch.endsWith("!");
        const symbol = rawMatch.replace(/^\$/, "").replace(/!$/, "");
        return { symbol, highPriority };
    });
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
              const symbols = parseSymbols(text);
              symbols.forEach(({ symbol, highPriority }) => notifyServer(symbol, highPriority));
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
