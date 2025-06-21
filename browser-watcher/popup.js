// popup.js

document.querySelectorAll(".tab-buttons button").forEach(btn => {
  btn.addEventListener("click", () => {
    document.querySelectorAll(".tab").forEach(tab => tab.classList.remove("active"));
    document.getElementById(btn.dataset.tab).classList.add("active");
  });
});

const whitelistInput = document.getElementById("whitelist-input");
const addWhitelistBtn = document.getElementById("add-whitelist");
const whitelistList = document.getElementById("whitelist-list");
const portInput = document.getElementById("notify-port");
const saveSettingsBtn = document.getElementById("save-settings");

function loadWhitelist() {
  chrome.storage.local.get(["whitelistedChannels"], (result) => {
    whitelistList.innerHTML = "";
    const list = result.whitelistedChannels || [];
    list.forEach(url => {
      const li = document.createElement("li");
      li.textContent = url;
      const removeBtn = document.createElement("button");
      removeBtn.textContent = "✕";
      removeBtn.style.marginLeft = "5px";
      removeBtn.onclick = () => {
        const updated = list.filter(item => item !== url);
        chrome.storage.local.set({ whitelistedChannels: updated }, loadWhitelist);
      };
      li.appendChild(removeBtn);
      whitelistList.appendChild(li);
    });

    // Auto-fill logic
    chrome.tabs.query({ active: true, currentWindow: true }, tabs => {
      const url = tabs[0]?.url || "";
      if (url.includes("https://discord.com/channels/") && !list.includes(url)) {
        whitelistInput.value = url;
      }
    });
  });
}

addWhitelistBtn.addEventListener("click", () => {
  const url = whitelistInput.value.trim();
  if (!url) return;
  chrome.storage.local.get(["whitelistedChannels"], (result) => {
    const current = result.whitelistedChannels || [];
    if (!current.includes(url)) {
      current.push(url);
      chrome.storage.local.set({ whitelistedChannels: current }, () => {
        whitelistInput.value = "";
        loadWhitelist();
      });
    }
  });
});

saveSettingsBtn.addEventListener("click", () => {
  const port = portInput.value;
  if (!port || isNaN(port) || port < 1 || port > 65535) {
    alert("Please enter a valid port.");
    return;
  }
  chrome.storage.local.set({ notifyPort: port }, () => {
    alert("Port saved.");
  });
});

chrome.storage.local.get(["notifyPort"], (result) => {
  portInput.value = result.notifyPort || "4113";
});

loadWhitelist();
