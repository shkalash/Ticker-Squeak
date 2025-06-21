// popup.js

const channelInput = document.getElementById("channelInput");
const addChannelBtn = document.getElementById("addChannelBtn");
const channelList = document.getElementById("channelList");

function renderChannels(channels) {
  channelList.innerHTML = "";
  channels.forEach((ch, i) => {
    const li = document.createElement("li");
    li.textContent = ch;

    const btn = document.createElement("button");
    btn.textContent = "Remove";
    btn.className = "remove";
    btn.onclick = () => {
      channels.splice(i, 1);
      saveChannels(channels);
      renderChannels(channels);
    };

    li.appendChild(btn);
    channelList.appendChild(li);
  });
}

function saveChannels(channels) {
  chrome.storage.local.set({ whitelistedChannels: channels });
}

function loadChannels() {
  chrome.storage.local.get("whitelistedChannels", (result) => {
    const channels = result.whitelistedChannels || [];
    renderChannels(channels);
  });
}

addChannelBtn.onclick = () => {
  const val = channelInput.value.trim();
  if (val) {
    chrome.storage.local.get("whitelistedChannels", (result) => {
      const channels = result.whitelistedChannels || [];
      if (!channels.includes(val)) {
        channels.push(val);
        saveChannels(channels);
        renderChannels(channels);
      }
    });
    channelInput.value = "";
  }
};

loadChannels();
