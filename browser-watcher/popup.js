document.addEventListener('DOMContentLoaded', () => {
    // Whitelist elements
    const whitelistList = document.getElementById('whitelist-list');
    const showModalButton = document.getElementById('show-add-modal-btn');

    // Settings elements
    const saveSettingsButton = document.getElementById('save-settings');
    const notifyPortInput = document.getElementById('notify-port');

    // Modal elements
    const modalContainer = document.getElementById('modal-container');
    const modalUrlWrapper = document.getElementById('modal-url-wrapper');
    const modalChannelUrlInput = document.getElementById('modal-channel-url');
    const modalChannelNameInput = document.getElementById('modal-channel-name');
    const modalSaveButton = document.getElementById('modal-save-btn');
    const modalCancelButton = document.getElementById('modal-cancel-btn');
    
    // A temporary variable to hold the URL while the modal is open
    let channelUrlToAdd = null;

    // --- Whitelist Logic ---

    function renderWhitelist(channels = []) {
        whitelistList.innerHTML = '';
        if (channels.length === 0) {
            const li = document.createElement('li');
            li.textContent = "No whitelisted channels.";
            li.style.color = "#64748b"; // slate-500
            whitelistList.appendChild(li);
            return;
        }

        channels.forEach((channel, index) => {
            const li = document.createElement('li');
            
            const nameSpan = document.createElement('span');
            nameSpan.textContent = channel.name || channel.url;
            nameSpan.title = channel.url;
            
            const removeButton = document.createElement('button');
            removeButton.classList.add('remove-btn');
            removeButton.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 16 16"><path d="M5.5 5.5A.5.5 0 0 1 6 6v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5m2.5 0a.5.5 0 0 1 .5.5v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5m3 .5a.5.5 0 0 0-1 0v6a.5.5 0 0 0 1 0z"/><path d="M14.5 3a1 1 0 0 1-1 1H13v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V4h-.5a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1H6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1h3.5a1 1 0 0 1 1 1zM4.118 4 4 4.059V13a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4.059L11.882 4zM2.5 3h11V2h-11z"/></svg>`;
            removeButton.addEventListener('click', () => {
                removeWhitelistItem(index);
            });

            li.appendChild(nameSpan);
            li.appendChild(removeButton);
            whitelistList.appendChild(li);
        });
    }

    function loadWhitelist() {
        chrome.storage.local.get(['whitelistedChannels'], (result) => {
            renderWhitelist(result.whitelistedChannels || []);
        });
    }

    function removeWhitelistItem(index) {
        chrome.storage.local.get(['whitelistedChannels'], (result) => {
            let channels = result.whitelistedChannels || [];
            channels.splice(index, 1);
            chrome.storage.local.set({ whitelistedChannels: channels }, () => {
                console.log('Whitelist updated.');
                loadWhitelist();
            });
        });
    }

    function hideModal() {
        modalContainer.classList.add('modal-hidden');
        modalChannelNameInput.value = '';
        modalChannelUrlInput.value = '';
        channelUrlToAdd = null;
    }

    // --- Event Listeners for new Modal ---
    
    showModalButton.addEventListener('click', () => {
        chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
            let isDiscordTab = false;
            if (tabs && tabs.length > 0) {
                const activeTab = tabs[0];
                if (activeTab.url && activeTab.url.includes("discord.com")) {
                    isDiscordTab = true;
                    channelUrlToAdd = activeTab.url;
                }
            }

            if (isDiscordTab) {
                // If we detected a discord URL, hide the manual URL input.
                modalUrlWrapper.classList.add('modal-hidden');
            } else {
                // Otherwise, show the manual URL input.
                channelUrlToAdd = null;
                modalUrlWrapper.classList.remove('modal-hidden');
            }
            
            // Show the modal in either case.
            modalContainer.classList.remove('modal-hidden');
            // Focus the correct input field.
            isDiscordTab ? modalChannelNameInput.focus() : modalChannelUrlInput.focus();
        });
    });

    modalCancelButton.addEventListener('click', hideModal);

    modalSaveButton.addEventListener('click', () => {
        const displayName = modalChannelNameInput.value.trim();
        let finalUrl = channelUrlToAdd; // Use detected URL by default

        // If no URL was auto-detected, get it from the input field
        if (!finalUrl) {
            finalUrl = modalChannelUrlInput.value.trim();
        }

        // --- Validation ---
        if (!displayName) {
            alert('Please enter a name for the channel.');
            modalChannelNameInput.focus();
            return;
        }
        if (!finalUrl || !finalUrl.includes("discord.com/channels/")) {
            alert('Please enter a valid Discord channel URL.');
            modalChannelUrlInput.focus();
            return;
        }

        const newChannel = { url: finalUrl, name: displayName };
        
        chrome.storage.local.get(['whitelistedChannels'], (result) => {
            let channels = result.whitelistedChannels || [];
            if (!channels.some(ch => ch.url === newChannel.url)) {
                channels.push(newChannel);
                chrome.storage.local.set({ whitelistedChannels: channels }, () => {
                    console.log('Whitelist saved successfully.');
                    loadWhitelist();
                    hideModal();
                });
            } else {
                alert('This channel is already in the whitelist.');
                hideModal();
            }
        });
    });

    // --- Settings Logic ---
    function saveSettings() {
        const port = notifyPortInput.value;
        chrome.storage.local.set({ notifyPort: port }, () => {
            console.log('Settings saved. Port:', port);
            alert('Settings saved!');
        });
    }

    function loadSettings() {
        chrome.storage.local.get(['notifyPort'], (result) => {
            if (result.notifyPort) {
                notifyPortInput.value = result.notifyPort;
            }
        });
    }

    saveSettingsButton.addEventListener('click', saveSettings);

    // Initial load
    loadWhitelist();
    loadSettings();
});
