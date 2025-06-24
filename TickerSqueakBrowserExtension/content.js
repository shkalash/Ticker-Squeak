console.log("[Ticker Squeak] content.js loaded");

// This Set will store tickers that have already been sent on the current page.
const sentTickers = new Set();
let whitelist = [];
let isPageActive = true;

window.addEventListener("beforeunload", () => {
  isPageActive = false;
});

// --- MODIFIED: Listener for requests from the popup ---
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  // Check if the message is a request for the current channel's info.
  if (request.type === "getChannelInfo") {
    console.log("[Ticker Squeak] Received request for channel info.");
    try {
      let channelName = document.title;
      
      // Clean up the title to get a friendlier name.
      // Removes prefixes like "• Discord | " or "Discord | "
      const prefixesToRemove = ["• Discord | ", "Discord | "];
      for (const prefix of prefixesToRemove) {
          if (channelName.startsWith(prefix)) {
              channelName = channelName.substring(prefix.length);
              break;
          }
      }
      // Removes the server name part, like " - My Server"
      const serverSeparatorIndex = channelName.lastIndexOf(' - ');
      if (serverSeparatorIndex > -1) {
          channelName = channelName.substring(0, serverSeparatorIndex);
      }
      
      const response = {
        url: location.href, // The full URL for matching
        name: channelName || "Unknown Channel" // The display name
      };

      console.log("[Ticker Squeak] Sending channel info back to popup:", response);
      sendResponse(response);
    } catch (e) {
      console.error("[Ticker Squeak] Error getting channel info:", e);
      sendResponse({ error: "Could not retrieve channel info." });
    }
    // Return true to indicate that we will send a response asynchronously.
    return true;
  }
});


function notifyServer(ticker, highPriority = false) {
  chrome.runtime.sendMessage({
    type: "notifyTicker",
    ticker,
    highPriority
  });
}

function parseTickers(text) {
    if (!text) return [];
    const tickerRegex = /(?:^|\s)(\$?[A-Z]{1,5}!?)(?=\s|$)/g;
    const matches = [...text.matchAll(tickerRegex)];

    return matches.map(match => {
        const rawMatch = match[1];
        const highPriority = rawMatch.endsWith("!");
        const ticker = rawMatch.replace(/^\$/, "").replace(/!$/, "");
        return { ticker, highPriority };
    });
}

function startDiscordObserver() {
  function observe(container) {
    console.log("[Ticker Squeak] Discord container found, starting observer.");
    const observer = new MutationObserver(mutations => {
      for (const mutation of mutations) {
        mutation.addedNodes.forEach(node => {
          if (!(node instanceof HTMLElement)) return;
          if (node.matches && node.matches("li[id^='chat-messages-']")) {
            const messageContent = node.querySelector('[id^="message-content-"]');
            if (messageContent) {
              const text = messageContent.innerText || messageContent.textContent;
              if (!text) return;
              const tickers = parseTickers(text);
              
                  tickers.forEach(({ ticker, highPriority }) => {
                    if (sentTickers.has(ticker)) {
                        if (highPriority) {
                            notifyServer(ticker, highPriority);
                        }
                    } else {
                        notifyServer(ticker, highPriority);
                        sentTickers.add(ticker);
                    }
                  });
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
      console.warn("[Ticker Squeak] Could not find Discord messages container.");
    }
  }

  waitForMessagesContainer();
}

function startOneOptionObserver() {
  console.log("[Ticker Squeak] Starting OneOption MutationObserver");
  const container = document.querySelector("#public > div > div.messages.main-chat.fixed-top");
  if (!container) {
    console.warn("[Ticker Squeak] OneOption messages container not found.");
    return;
  }

  const observer = new MutationObserver(() => {
    container.querySelectorAll("a[data-symbol]").forEach(el => {
      const sym = el.getAttribute("data-symbol");
      if (sym && /^[A-Z]{1,6}$/.test(sym)) {
        if (!sentTickers.has(sym)) {
            notifyServer(sym);
            sentTickers.add(sym);
        }
      }
    });
  });

  observer.observe(container, { childList: true, subtree: true });
}

function init() {
  try {
    // Note: The whitelist now stores objects: {url: string, name: string}
    chrome.storage.local.get(["whitelistedChannels"], (result) => {
      whitelist = result.whitelistedChannels || [];

      if (location.hostname.includes("discord.com")) {
        if (!whitelist.some(channel => location.href.startsWith(channel.url))) {
          console.log("[Ticker Squeak] Discord channel not whitelisted, skipping scan.");
          return;
        }
        startDiscordObserver();
      }

      if (location.hostname.includes("oneoption.com")) {
        startOneOptionObserver();
      }
    });
  } catch (err) {
    console.warn("[Ticker Squeak] Storage load failed:", err);
  }
}

init();
