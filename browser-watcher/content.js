// content.js

console.log("[Symbol Watcher] content.js loaded");

let port = chrome.runtime.connect({ name: "symbol-watcher-port" });

let discordScanIntervalMs = 2000;
let ignoreSet = new Set([
  "EMA", "SMA", "PA", "HOD", "LOD", "VWAP",
  "SPY", "QQQ", "PCS", "BPS", "CDS", "CCS", "IC", "I", "EOD", "ATH", "WR","BO","CPI","PPI","JOLTS"
]);

let whitelist = [];
let scannerStarted = false;
let intervalId = null;

function extractSymbolsFromText(text) {
  const matches = [...text.matchAll(/\b\$?[A-Z]{1,6}\b/g)];
  return matches
    .map(m => m[0].replace(/^\$/, ""))
    .filter(sym => !ignoreSet.has(sym));
}

function logSymbols(symbols) {
  const unique = Array.from(symbols).filter(sym => typeof sym === "string" && sym.trim() !== "");
  if (unique.length === 0) return;
  chrome.runtime.sendMessage({ action: "logSymbols", symbols: unique });
}

function startDiscordScanner() {
  if (scannerStarted) return;

  if (!discordScanIntervalMs || typeof discordScanIntervalMs !== "number") {
    console.warn("[Symbol Watcher] Invalid scan interval, using default 2000ms");
    discordScanIntervalMs = 2000;
  }

  scannerStarted = true;
  console.log(`[Symbol Watcher] Starting Discord symbol scanner every ${discordScanIntervalMs}ms`);

  intervalId = setInterval(() => {
    const messageDivs = document.querySelectorAll('div[class*="contents_"]');
    const found = new Set();

    messageDivs.forEach(div => {
      const text = div.innerText || "";
      const symbols = extractSymbolsFromText(text);
      symbols.forEach(sym => found.add(sym));
    });

    if (found.size > 0) {
      logSymbols(found);
    }
  }, discordScanIntervalMs);
}

function stopDiscordScanner() {
  if (scannerStarted && intervalId) {
    clearInterval(intervalId);
    scannerStarted = false;
    console.log("[Symbol Watcher] Discord scanner stopped");
  }
}

function maybeStartScanner() {
  const url = window.location.href;
  const isDiscord = url.includes("discord.com/channels/");
  const isOneOption = url.includes("app.oneoption.com/chat");
  const whitelisted = whitelist.some(w => url.startsWith(w));

  if (isOneOption) {
    watchOneOption();
  } else if (isDiscord && whitelisted) {
    startDiscordScanner();
  } else {
    stopDiscordScanner();
  }
}

function watchOneOption() {
  const selector = "#public > div > div.messages.main-chat.fixed-top";

  const waitForContainer = (sel, callback) => {
    const el = document.querySelector(sel);
    if (el) callback(el);
    else setTimeout(() => waitForContainer(sel, callback), 1000);
  };

  waitForContainer(selector, (container) => {
    const observer = new MutationObserver((mutations) => {
      const found = new Set();
      mutations.forEach(mutation => {
        mutation.addedNodes.forEach(node => {
          if (node.nodeType !== Node.ELEMENT_NODE) return;
          const links = node.querySelectorAll("a[data-symbol]");
          links.forEach(link => {
            const symbol = link.getAttribute("data-symbol");
            if (symbol && !ignoreSet.has(symbol)) {
              found.add(symbol);
            }
          });
        });
      });

      if (found.size > 0) {
        logSymbols(found);
      }
    });

    observer.observe(container, { childList: true, subtree: true });
    console.log("[Symbol Watcher] OneOption observer active");
  });
}

chrome.storage.local.get(["userIgnoreList", "whitelistedChannels", "discordScanInterval"], (result) => {
  const customIgnore = result.userIgnoreList || [];
  whitelist = result.whitelistedChannels || [];
  discordScanIntervalMs = result.discordScanInterval || 2000;

  customIgnore.forEach(sym => ignoreSet.add(sym));
  maybeStartScanner();

  let lastUrl = location.href;
  setInterval(() => {
    if (location.href !== lastUrl) {
      lastUrl = location.href;
      console.log("[Symbol Watcher] URL changed:", lastUrl);
      maybeStartScanner();
    }
  }, 1000);
});

// Listen for clear request from popup to stop scanning & clear notified set if needed
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === "clearNotified") {
    stopDiscordScanner();
    sendResponse({ status: "stopped" });
  }
});
