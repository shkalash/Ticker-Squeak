console.log("[Ticker Squeak] content.js loaded");

// --- START: New York Time Logic ---
// Get the current date string in YYYY-MM-DD format for the 'America/New_York' timezone.
const NY_CURRENT_DATE_STRING = new Date().toLocaleDateString('en-CA', {
    timeZone: 'America/New_York',
});

/**
 * Checks if a given Date object corresponds to the current day in New York.
 * @param {Date} messageDate The Date object of the message timestamp.
 * @returns {boolean} True if the message is from the current day in NY, false otherwise.
 */
function isFromCurrentDayInNY(messageDate) {
    if (!messageDate || isNaN(messageDate)) {
        return false; // Invalid date passed
    }
    const messageNYDateString = messageDate.toLocaleDateString('en-CA', {
        timeZone: 'America/New_York',
    });
    return messageNYDateString === NY_CURRENT_DATE_STRING;
}
// --- END: New York Time Logic ---

let whitelist = [];
let isPageActive = true;

window.addEventListener("beforeunload", () => {
  isPageActive = false;
});

// Listener for requests from the popup for channel info
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.type === "getChannelInfo") {
    // ... this logic remains the same as your original file
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
    // UPDATED REGEX: The lookahead now includes comma, period, and question mark.
    const tickerRegex = /(?:^|\s)(\$?[A-Z]{1,5}!?)(?=[\s,.?]|$)/g;
    const matches = [...text.matchAll(tickerRegex)];

    return matches.map(match => {
        const rawMatch = match[1];
        const highPriority = rawMatch.endsWith("!");
        const ticker = rawMatch.replace(/^\$/, "").replace(/!$/, "");
        return { ticker, highPriority };
    });
}

/**
 * Parses a "h:mm:ss AM/PM" timestamp from OneOption into a Date object.
 * @param {string} timeString The timestamp string, e.g., "3:09:41 PM".
 * @returns {Date | null} A Date object representing the time, or null if parsing fails.
 */
function parseOneOptionTimestamp(timeString) {
    const now = new Date();
    const match = timeString.match(/(\d{1,2}):(\d{2}):(\d{2})\s(AM|PM)/);

    if (!match) return null;

    let [_, hours, minutes, seconds, period] = match;
    hours = parseInt(hours, 10);

    if (period === 'PM' && hours < 12) hours += 12;
    if (period === 'AM' && hours === 12) hours = 0;

    const messageDate = new Date();
    messageDate.setHours(hours, parseInt(minutes, 10), parseInt(seconds, 10), 0);

    if (messageDate > now) {
        messageDate.setDate(now.getDate() - 1);
    }
    return messageDate;
}

function startDiscordObserver() {
  function observe(container) {
    console.log("[Ticker Squeak] Discord container found, starting observer.");
    const observer = new MutationObserver(mutations => {
      for (const mutation of mutations) {
        mutation.addedNodes.forEach(node => {
          if (!(node instanceof HTMLElement) || !node.matches("li[id^='chat-messages-']")) return;

          const timeElement = node.querySelector("time[datetime]");
          if (!timeElement) return; // Cannot verify date, skip

          const messageTime = new Date(timeElement.getAttribute('datetime'));
          if (!isFromCurrentDayInNY(messageTime)) {
              return; // Skip if message is not from current NY day
          }

          const messageContent = node.querySelector('[id^="message-content-"]');
          if (messageContent) {
            const text = messageContent.innerText || messageContent.textContent;
            if (!text) return;
            const tickers = parseTickers(text);
            
            tickers.forEach(({ ticker, highPriority }) => {
              notifyServer(ticker, highPriority);
            });
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
      const messageElement = el.closest('div.message');
      if (!messageElement) return;

      const timeElement = messageElement.querySelector("div.m-time");
      if (!timeElement) return;

      const messageTime = parseOneOptionTimestamp(timeElement.textContent);
      if (!isFromCurrentDayInNY(messageTime)) {
          return; // Skip if message is not from current NY day
      }

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
