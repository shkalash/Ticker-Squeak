// content.js

console.log("[Symbol Watcher] content.js loaded");

let discordScanIntervalMs = 2000;
let ignoreSet = new Set([
  "EMA", "SMA", "PA", "HOD", "LOD", "VWAP",
  "SPY", "QQQ", "PCS", "BPS", "CDS", "CCS",
  "IC", "I", "EOD", "ATH", "WR", "BO", "CPI",
  "PPI", "JOLTS"
]);

let whitelist = [];
let scannerStarted = false;
let intervalId = null;
let isPageActive = true;

// Clean up on tab unload
window.addEventListener("beforeunload", () => {
  isPageActive = false;
  clearInterval(intervalId);
});

// --- Utility ---

function extractSymbolsFromText(text) {
  const matches = [...text.matchAll(/\b\$?[A-Z]{1,6}\b/g)];
  return matches
    .map(m => m[0].replace(/^\$/, ""))
    .filter(sym => !ignoreSet.has(sym));
}

function logSymbols(symbols) {
  const unique = Array.from(symbols).filter(sym =>
    typeof sym === "string" && sym.trim() !== ""
  );
  if (unique.length === 0 || !isPageActive || !chrome?.runtime?.id) return;

  try {
    chrome.runtime.sendMessage({ action: "logSymbols", symbols: unique });
  } catch (err) {
    console.warn("Symbol log failed, extension context might be gone:", err);
  }
}

// --- Message handler ---

chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (msg.action === "updateScanInterval") {
    discordScanIntervalMs = parseInt(msg.value, 10) || 2000;
    if (intervalId) {
      clearInterval(intervalId);
      startScanner();
    }
    sendResponse({ status: "updated" });
  }
});

// --- Main Scanner Setup ---

function startScanner() {
  if (scannerStarted || !isPageActive) return;
  scannerStarted = true;

  const isDiscord = location.hostname.includes("discord.com");
  const isOneOption = location.hostname.includes("oneoption.com");

  if (isOneOption) {
    const container = document.querySelector("#public > div > div.messages.main-chat.fixed-top");
    if (!container) return;

    const observer = new MutationObserver(() => {
      const symbols = [];
      container.querySelectorAll("a[data-symbol]").forEach(el => {
        const sym = el.getAttribute("data-symbol");
        if (sym && /^[A-Z]{1,6}$/.test(sym) && !ignoreSet.has(sym)) {
          symbols.push(sym);
        }
      });
      logSymbols(symbols);
    });

    observer.observe(container, { childList: true, subtree: true });
    console.log("[Symbol Watcher] OneOption scanner activated.");
  }

  if (isDiscord) {
    console.log(`[Symbol Watcher] Starting Discord symbol scanner every ${discordScanIntervalMs}ms`);

    intervalId = setInterval(() => {
      const messages = document.querySelectorAll('[id^="chat-messages"] .contents_c19a55');
      const symbols = [];

      messages.forEach(msg => {
        if (msg?.innerText) {
          const found = extractSymbolsFromText(msg.innerText);
          symbols.push(...found);
        }
      });

      logSymbols(symbols);
    }, discordScanIntervalMs);
  }
}

// --- Load Ignore List + Whitelist ---

try {
  if (chrome?.storage?.local) {
    chrome.storage.local.get(["userIgnoreList", "whitelistedChannels", "discordScanInterval"], result => {
      ignoreSet = new Set(result.userIgnoreList || []);
      whitelist = result.whitelistedChannels || [];
      discordScanIntervalMs = result.discordScanInterval || 2000;

      const currentUrl = location.href;

      if (
        location.hostname.includes("discord.com") &&
        !whitelist.some(prefix => currentUrl.startsWith(prefix))
      ) {
        console.log("[Symbol Watcher] Discord channel not whitelisted, skipping.");
        return;
      }

      startScanner();
    });
  }
} catch (err) {
  console.warn("[Symbol Watcher] Unable to load storage or extension context invalidated:", err);
}
