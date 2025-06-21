document.addEventListener("DOMContentLoaded", () => {
  const tabs = document.querySelectorAll(".tab");
  const tabContents = document.querySelectorAll(".tab-content");

  const logDiv = document.getElementById("log");
  const clearBtn = document.getElementById("clear-list");
  const ignoreListDiv = document.getElementById("ignore-list");
  const whitelistListDiv = document.getElementById("whitelist-list");

  const settingsForm = document.getElementById("settings-form");
  const scanIntervalInput = document.getElementById("scan-interval");
  const settingsStatus = document.getElementById("settings-status");

  const whitelistForm = document.getElementById("whitelist-form");
  const whitelistInput = document.getElementById("whitelist-input");

  let symbolsArray = [];
  let ignoreSet = new Set();
  let whitelist = [];

  const port = chrome.runtime.connect({ name: "symbol-watcher-port" });

  // Tab switching
  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      tabs.forEach(t => t.classList.remove("active"));
      tab.classList.add("active");

      tabContents.forEach(tc => tc.classList.remove("active"));
      document.getElementById(tab.dataset.tab).classList.add("active");
    });
  });

  function loadStorage() {
    chrome.storage.local.get(
      ["userIgnoreList", "whitelistedChannels", "discordScanInterval"],
      (result) => {
        ignoreSet = new Set(result.userIgnoreList || []);
        whitelist = result.whitelistedChannels || [];
        renderIgnoreList();
        renderWhitelist();
        renderLog();
        scanIntervalInput.value = result.discordScanInterval || 2000;
      }
    );
  }

  function saveIgnoreSet() {
    chrome.storage.local.set({ userIgnoreList: Array.from(ignoreSet) });
  }

  function saveWhitelist() {
    chrome.storage.local.set({ whitelistedChannels: whitelist });
  }

  function saveScanInterval(ms) {
    chrome.storage.local.set({ discordScanInterval: ms });
  }

  function renderLog() {
    logDiv.innerHTML = "";

    const filtered = symbolsArray.filter(sym => !ignoreSet.has(sym));
    if (filtered.length === 0) {
      logDiv.textContent = "No symbols detected yet.";
      return;
    }

    filtered.forEach(sym => {
      const el = document.createElement("div");
      el.textContent = sym;

      const ignoreBtn = document.createElement("span");
      ignoreBtn.className = "icon-btn";
      ignoreBtn.title = `Ignore ${sym}`;
      ignoreBtn.textContent = "×";
      ignoreBtn.addEventListener("click", () => {
        ignoreSet.add(sym);
        saveIgnoreSet();
        renderIgnoreList();
        renderLog();
      });

      el.appendChild(ignoreBtn);
      logDiv.appendChild(el);
    });
  }

  function renderIgnoreList() {
    ignoreListDiv.innerHTML = "";

    if (ignoreSet.size === 0) {
      ignoreListDiv.textContent = "Ignore list is empty.";
      return;
    }

    Array.from(ignoreSet).sort().forEach(sym => {
      const el = document.createElement("div");
      el.textContent = sym;

      const removeBtn = document.createElement("span");
      removeBtn.className = "icon-btn";
      removeBtn.title = `Remove ${sym} from ignore`;
      removeBtn.textContent = "×";
      removeBtn.addEventListener("click", () => {
        ignoreSet.delete(sym);
        saveIgnoreSet();
        renderIgnoreList();
        renderLog();
      });

      el.appendChild(removeBtn);
      ignoreListDiv.appendChild(el);
    });
  }

  function renderWhitelist() {
    whitelistListDiv.innerHTML = "";

    if (whitelist.length === 0) {
      whitelistListDiv.textContent = "Whitelist is empty.";
      return;
    }

    whitelist.forEach((urlPrefix, i) => {
      const el = document.createElement("div");
      el.textContent = urlPrefix;

      const removeBtn = document.createElement("span");
      removeBtn.className = "icon-btn";
      removeBtn.title = `Remove ${urlPrefix} from whitelist`;
      removeBtn.textContent = "×";
      removeBtn.addEventListener("click", () => {
        whitelist.splice(i, 1);
        saveWhitelist();
        renderWhitelist();
      });

      el.appendChild(removeBtn);
      whitelistListDiv.appendChild(el);
    });
  }

  settingsForm.addEventListener("submit", (e) => {
    e.preventDefault();
    let val = parseInt(scanIntervalInput.value, 10);
    if (isNaN(val) || val < 500) {
      settingsStatus.textContent = "Please enter a number >= 500.";
      settingsStatus.style.color = "red";
      return;
    }
    saveScanInterval(val);
    settingsStatus.textContent = "Settings saved.";
    settingsStatus.style.color = "green";

    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
      if (tabs[0]?.id) {
        chrome.tabs.sendMessage(tabs[0].id, {
          action: "updateScanInterval",
          value: val,
        });
      }
    });
  });

  whitelistForm.addEventListener("submit", (e) => {
    e.preventDefault();
    const val = whitelistInput.value.trim();
    if (val && !whitelist.includes(val)) {
      whitelist.push(val);
      saveWhitelist();
      renderWhitelist();
      whitelistInput.value = "";
    }
  });

  port.onMessage.addListener((msg) => {
    if (msg.symbols) {
      symbolsArray = msg.symbols;
      renderLog();
    }
    if (msg.status === "cleared") {
      symbolsArray = [];
      renderLog();
    }
  });

  port.postMessage({ action: "requestLog" });

  clearBtn.addEventListener("click", () => {
    port.postMessage({ action: "clearNotified" });
  });

  loadStorage();
});
