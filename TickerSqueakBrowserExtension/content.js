//console.log("[Ticker Squeak] DEBUG version loaded. All steps will be logged.");

/**
 * Checks if a given Date object corresponds to the current day in New York.
 * @param {Date} messageDate The Date object of the message timestamp.
 * @returns {boolean} True if the message is from the current day in NY, false otherwise.
 */
function isFromCurrentDayInNY(messageDate) {
    if (!messageDate || isNaN(messageDate)) {
        //console.log("[Ticker Squeak] isFromCurrentDayInNY: received invalid date.");
        return false;
    }
    const currentNYDateString = new Date().toLocaleDateString('en-CA', { timeZone: 'America/New_York' });
    const messageNYDateString = messageDate.toLocaleDateString('en-CA', { timeZone: 'America/New_York' });
    const isMatch = messageNYDateString === currentNYDateString;
    
    //console.log(`[Ticker Squeak] Timestamp Check -> Message NY Date: ${messageNYDateString}, Current NY Date: ${currentNYDateString}, Match: ${isMatch}`);
    return isMatch;
}

let whitelist = [];
let isPageActive = true;
let cachedNotifyPort = "4113"; // Fallback default; kept in sync with popup/background via storage

window.addEventListener("beforeunload", () => {
  isPageActive = false;
});

function notifyServer(ticker, highPriority = false) {
  // Primary path: extension messaging API
  try {
    if (typeof chrome !== 'undefined' && chrome.runtime && typeof chrome.runtime.sendMessage === 'function') {
      chrome.runtime.sendMessage({ type: "notifyTicker", ticker, highPriority });
      return;
    }
    if (typeof browser !== 'undefined' && browser.runtime && typeof browser.runtime.sendMessage === 'function') {
      browser.runtime.sendMessage({ type: "notifyTicker", ticker, highPriority });
      return;
    }
  } catch (e) {
    // fall through to fetch fallback
  }

  // Fallback: direct fetch to local notifier (works on Discord if runtime is unavailable)
  try {
    fetch(`http://127.0.0.1:${cachedNotifyPort}/notify`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ ticker, highPriority })
    }).catch(() => {});
  } catch (e) {
    // Swallow to avoid noisy console in page
  }
}

function parseTickers(text) {
    if (!text) return [];
    //console.log(`[Ticker Squeak] Parsing text for tickers: "${text}"`);
    const tickerRegex = /(?:^|[\s,])(\$?[A-Z]{1,5}!?)(?=[\s,.?]|$)/g;
    const matches = [...text.matchAll(tickerRegex)];

    if (matches.length === 0) {
        return [];
    }

    const rawFinds = matches.map(match => match[1]);
    //console.log(`[Ticker Squeak] Regex found raw tickers: ${rawFinds.join(', ')}`);

    return rawFinds.map(rawMatch => {
        const highPriority = rawMatch.endsWith("!");
        const ticker = rawMatch.replace(/^\$/, "").replace(/!$/, "");
        if (ticker) {
            return { ticker, highPriority };
        }
        return null;
    }).filter(Boolean); // Removes any null entries
}

/**
 * Parses a OneOption timestamp, now with support for the "Ytd, " prefix.
 * @param {string} timeString The timestamp string.
 * @returns {Date | null} A Date object representing the time, or null if parsing fails.
 */
function parseOneOptionTimestamp(timeString) {
    const now = new Date();
    let isYesterday = false;

    // Check for the "Ytd, " prefix.
    if (timeString.startsWith("Ytd, ")) {
        isYesterday = true;
        timeString = timeString.substring(5); // Remove prefix for parsing
    }

    const match = timeString.match(/(\d{1,2}):(\d{2}):(\d{2})\s(AM|PM)/);
    if (!match) return null;

    let [_, hours, minutes, seconds, period] = match;
    hours = parseInt(hours, 10);
    if (period === 'PM' && hours < 12) hours += 12;
    if (period === 'AM' && hours === 12) hours = 0;
    
    const messageDate = new Date();
    messageDate.setHours(hours, parseInt(minutes, 10), parseInt(seconds, 10), 0);

    // Set the date correctly based on "Ytd" or current time
    if (isYesterday) {
        messageDate.setDate(now.getDate() - 1);
    } else if (messageDate > now) {
        // Handles edge case of viewing yesterday's message after midnight
        messageDate.setDate(now.getDate() - 1);
    }

    return messageDate;
}

function startDiscordObserver() {
  function observe(container) {
    const observer = new MutationObserver(mutations => {
      //console.log(`[Ticker Squeak] Discord observer fired with ${mutations.length} mutations.`);
      for (const mutation of mutations) {
        mutation.addedNodes.forEach(node => {
          if (!(node instanceof HTMLElement) || !node.matches("li[id^='chat-messages-']")) return;
          //console.log("[Ticker Squeak] Found new message node:", node);

          const timeElement = node.querySelector("time[datetime]");
          if (!timeElement) {
            //console.log("[Ticker Squeak] SKIPPING: No time element found in message node.");
            return;
          }

          const messageTime = new Date(timeElement.getAttribute('datetime'));
          //console.log(`[Ticker Squeak] Found message time: ${messageTime.toISOString()}`);
          if (!isFromCurrentDayInNY(messageTime)) {
              //console.log("[Ticker Squeak] SKIPPING: Message is not from current NY day.");
              return;
          }

          const messageContent = node.querySelector('[id^="message-content-"]');
          if (messageContent) {
            const text = messageContent.innerText || messageContent.textContent;
            if (!text) {
                //console.log("[Ticker Squeak] SKIPPING: Message node has no text content.");
                return;
            }
            const tickers = parseTickers(text);
            if (tickers.length === 0) {
                //console.log("[Ticker Squeak] No tickers found in message.");
            }
            tickers.forEach(({ ticker, highPriority }) => {
              notifyServer(ticker, highPriority);
            });
          } else {
            //console.log("[Ticker Squeak] SKIPPING: No message content element found.");
          }
        });
      }
    });
    observer.observe(container, { childList: true, subtree: true });
    //console.log("[Ticker Squeak] Discord observer is now observing the container.");
  }

  function waitForMessagesContainer(retries = 40, delay = 500) {
    const container = document.querySelector('[data-list-id="chat-messages"]');
    if (container) {
      observe(container);
    } else if (retries > 0) {
      setTimeout(() => waitForMessagesContainer(retries - 1, delay), delay);
    }
  }
  waitForMessagesContainer();
}

function startOneOptionObserver() {
  const container = document.querySelector("#public > div > div.messages.main-chat.fixed-top");
  if (!container) return;

  const observer = new MutationObserver(() => {
    //console.log("[Ticker Squeak] OneOption observer fired.");
    container.querySelectorAll("a[data-symbol]").forEach(el => {
      const sym = el.getAttribute("data-symbol");
      //console.log(`[Ticker Squeak] Found potential OneOption ticker element for: ${sym}`);
      
      // The correct parent message selector is '.m-item'.
      const messageElement = el.closest('.m-item');

      if (!messageElement) {
          //console.log(`[Ticker Squeak] SKIPPING ${sym}: Could not find parent message element (tried .m-item).`);
          return;
      }
      const timeElement = messageElement.querySelector("div.m-time");
      if (!timeElement) {
          //console.log(`[Ticker Squeak] SKIPPING ${sym}: Could not find time element in parent.`);
          return;
      }
      const timeString = timeElement.textContent;
      const messageTime = parseOneOptionTimestamp(timeString);
      //console.log(`[Ticker Squeak] Found OneOption time string: "${timeString}", Parsed: ${messageTime?.toISOString()}`);
      if (!isFromCurrentDayInNY(messageTime)) {
          //console.log(`[Ticker Squeak] SKIPPING ${sym}: Message is not from current NY day.`);
          return;
      }
      if (sym && /^[A-Z]{1,6}$/.test(sym)) {
        notifyServer(sym);
      }
    });
  });
  observer.observe(container, { childList: true, subtree: true });
  //console.log("[Ticker Squeak] OneOption observer is now observing the container.");
}

function init() {
  //console.log("[Ticker Squeak] init() called.");
  try {
    chrome.storage.local.get(["whitelistedChannels", "notifyPort"], (result) => {
      whitelist = result.whitelistedChannels || [];
      if (result.notifyPort) {
        cachedNotifyPort = String(result.notifyPort);
      }
      //console.log(`[Ticker Squeak] Whitelist loaded with ${whitelist.length} channels.`);

      if (location.hostname.includes("discord.com")) {
        //console.log("[Ticker Squeak] On Discord page.");
        if (!whitelist.some(channel => location.href.startsWith(channel.url))) {
          //console.log("[Ticker Squeak] SKIPPING: Discord channel is not whitelisted:", location.href);
          return;
        }
        //console.log("[Ticker Squeak] Discord channel IS whitelisted. Starting observer.");
        startDiscordObserver();
      }

      if (location.hostname.includes("oneoption.com")) {
        //console.log("[Ticker Squeak] On OneOption page. Starting observer.");
        startOneOptionObserver();
      }
    });
  } catch (err) {
    console.error("[Ticker Squeak] CRITICAL ERROR in init():", err);
  }
}

init();
