# Ticker Squeak User Manual

## Overview

Ticker Squeak is a productivity tool for traders designed to solve the problem of information overload from busy trading chat rooms and Discord channels. It captures stock ticker symbols mentioned in web pages and organizes them in a native macOS application, preventing traders from having to manually sift through conversations to find actionable ideas.

The system consists of two core components: a **Browser Extension** that monitors websites and a native **Swift macOS Client** where you interact with the captured tickers.

***

## Browser Extension

The browser extension is the data source for the Ticker Squeak application. Its job is to monitor supported websites (OneOption and specific Discord channels) for ticker symbols posted during the current trading day and send them to the macOS app.

### Configuration

To configure the extension, click on the Ticker Squeak icon in your browser's toolbar to open a popup window.

* **Discord Channel Whitelist**
    * The extension will only monitor Discord channels that you have explicitly added to this whitelist.
    * **To Add a Channel:** Click the "Add Channel" button. If you are currently on a Discord channel page, the URL will be automatically detected. You only need to provide a "Friendly Name" for it. If you are on another website, you will need to manually enter both the full Discord Channel URL and a friendly name.
    * **To Remove a Channel:** Click the trash can icon next to any channel in the list.

* **Settings**
    * **Notification Port:** This is the network port that the extension uses to send data to your macOS application.
    * **Important:** This port number **must** match the port number configured in the **Server Settings** of the macOS application for the two components to communicate successfully.

***

## The Main Ticker Feed

This is the primary screen where all captured tickers appear in an inbox-style list. You can perform numerous actions from this view.

### Filtering and Display

* **Filter Unread**: Click the **envelope** icon to show only tickers you haven't interacted with yet. A counter displays the total number of unread items.
* **Filter Starred**: Click the **star** icon to show only tickers you've marked as important.
* **Filter by Direction**: Use the **uptrend** (bullish) and **downtrend** (bearish) buttons to filter tickers based on the direction you've assigned to them.
* **Toggle All Directions**: Click the button showing both an **uptrend and downtrend** icon together to toggle all direction filters. If no direction filters are active, it will turn both on; otherwise, it will turn both off.
* **Floating SPY Window**: Click the **OneOption logo** to open a separate, always-on-top window displaying the SPY chart from the OneOption website.
* **Toggle Sound**: Mute or unmute sound alerts for new tickers using the **speaker** icon.

### Ticker Actions

For each ticker in the list, you have a set of actions:

* **Open in Charting Software**: Clicking directly on the ticker symbol will open its chart in your selected charting software (e.g., Option Stalker Pro or TradingView). This action also automatically marks the ticker as read.
* **Mark Read/Unread**: Click the circle icon to toggle the ticker's read status.
* **Star**: Mark a ticker as important.
* **Set Direction**: The direction button allows for quick triage of a ticker's chart. **Left-click** to set it to **bullish** (uptrend), **right-click** to set it to **bearish** (downtrend), or **middle-click** to set it back to **neutral**.
* **Create/View Trade Idea**: Click the **lightbulb** icon to open the detailed Trade Checklist view for this ticker. This automatically marks the ticker as read and starred for easy tracking.
* **Hide**: Temporarily hide the ticker for a short period.
* **Snooze**: Hide the ticker for the rest of the trading day.
* **Ignore**: Permanently add the ticker to your ignore list so you won't be alerted to it again.

### Multi-Selection Toolbar

When you select multiple tickers in the list, a special toolbar appears, allowing you to perform bulk actions like toggling read/unread, starring, hiding, snoozing, ignoring, or setting a direction for all selected items at once.

***

## Trading Strategy and Preparation Tools

Ticker Squeak integrates tools to enforce a systematic trading approach.

* **Pre-Market Checklist**: This view provides a checklist template to help you prepare for the trading day. It features collapsible sections, and you can navigate to previous days using the calendar or jump directly to today. Completed checklists can be exported as Markdown files.
* **Trade Ideas**: This feature allows you to log and systematically evaluate potential trades. You can view ideas logged for a specific day and create new ones. Clicking an idea opens a detailed checklist where you can change its status (Idea, Taken, or Rejected) and open the ticker in a charting service. These checklists can also be exported.

***

## Managing Ticker Lists

The application provides dedicated views to manage tickers you've previously filtered out.

* **Hidden Tickers**: View all tickers you've temporarily hidden and choose to "reveal" them immediately, bringing them back to the main feed.
* **Snoozed Tickers**: See all tickers that are snoozed for the day and manually remove them from the snooze list if desired.
* **Ignore List**: Manage the list of tickers you have permanently ignored. You can add tickers manually or remove existing ones to allow them back into your feed.

***

## Settings

The settings screen is organized into three main tabs: General, Server, and Charting.

### General Settings

This tab combines settings for list behavior and notifications.

* **List Settings**
    * **Hide Ticker Cooldown**: Set the number of minutes a ticker will remain hidden before it can reappear in your feed.
    * **Clear Snooze List Daily at**: Choose a time of day when the list of snoozed tickers will be automatically cleared.
* **Notification Method**
    * **In-App Banners**: Toggle on or off to receive notifications within the app itself.
    * **Desktop Notifications**: Toggle on or off to receive standard macOS notifications. If permissions have not been granted, a button will appear allowing you to request access. The app shows the current permission status (granted, denied, or requires permission).
* **Notifications Audio**
    * For each type of notification sound, you can select a specific audio file from the list of built-in macOS system sounds.
    * A play button next to each picker allows you to preview the selected sound.

### Server Settings

This tab allows you to configure the local server that receives tickers from the browser extension.

* **Server Port**: Change the port number the local server listens on. You must click **Apply** to save the change or **Revert** to cancel.
* **Server Status**: View the current status of the server (e.g., "Listening" or "Stopped"). A colored circle (green for on, red for off) gives a quick visual indicator. You can also **Start** or **Stop** the server manually using the provided button.

### Charting Settings

This tab is for configuring automation with your charting software.

* **OneOption Integration**
    * **Enable OneOption Automation**: Toggle to enable or disable integration with Option Stalker Pro.
    * **Chart Group**: Select which chart group to send the ticker to.
    * **Time Frame**: Select the chart time frame to load.
* **TradingView Integration**
    * **Enable TradingView Automation**: Toggle to enable or disable integration with TradingView. This requires special **Accessibility permissions** from macOS.
    * **Permissions**: If access has not been granted, an icon and a button will appear, allowing you to open the system prompt to grant permission. The app will reflect when access is granted.
    * **Tab Switching**: When enabled, you can configure the automation to switch to a specific tab within TradingView.
