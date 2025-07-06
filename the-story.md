# Ticker Squeak

Ticker Squeak started as a simple need. During the trading day, the [OneOption](https://oneoption.com/) chat room, and the Discord channels can get a bit noisy. As you are reviewing charts, settings alerts, and finding the best trades, your attention is utterly focused. 

But the chat room and discord channel provide an immense resource, as other traders post their own trades and callout great looking charts, ones that you should give your attention to as well.

But as the dynamic and fast paced environment of day trading dictates, manually scrolling back, finding those tickers, and starting to look at the charts, seemed to me like an inefficient usage of time. 

#### Episode I - The Ticker Menace

The original idea was simple. Develop a browser extension that will read the pages of interest, and provide notifications over http when a ticker is called out. With the help of ChatGPT, I Analyzed the websites produced [TickerSqueakBrowserExtension](https://github.com/shkalash/Ticker-Squeak/tree/main/TickerSqueakBrowserExtension), which covered all the bases needed to hook into the websites, find the tickers as they are posted, do some basic filtering (only send tickers from the current day) and send those off to the localhost at a selected port.

Initially, I just ran a simple Node.js server on my machine, configured to receive the notification, and fire a local Mac OS notification, this solved the problem of sifting through the rooms, or reading every message that comes in, but there was much room to grow.

#### Episode II - Attack of the LLM

In came a simple [Swift MacOS client](https://github.com/shkalash/Ticker-Squeak/tree/main/macos/TickerSqueak) to do the work. Originally it was a simple inbox interface, allowing to track what was coming in, star tickers of interest, and ignore tickers and keywords that would get past the filter but were of no value. While this was helpful, it still didn't provide a streamlined experience I came to expect after two decades of building software.

As a software architect and lead developer, I decided to build my team. Gemini Pro which I had access to become my Junior developer. ChatGPT and Claude helped here and there as outside consultants. It was an easy decision, I had the fire power to generate code quickly, while keeping the high level decisions and architectural design my own, instructing and code reviewing the team to fit my designs and principles. 

Ideas and features began to flow, and within a week of work, I had a robust scalable, decoupled application that was able to not only track the incoming data and keep it organized in an easy to use fashion, but also allowed to quickly view and respond to the data, as I integrated methods to open the incoming alerts in both Option Stalker Pro and TradingView.

#### Episode III - Revenge of the Trader

After using the software for a week, I decided to take some extra step that enabled me to track and compliment my trading strategy before and during the day. 

I added my pre market routine tracker, and integrated trade ideas, with the intention of providing a systematically defined approach and evaluation process to the decision making taking during the day. This was heavily inspired by the profound teachings of Pete over at [OneOption](https://oneoption.com/) and the fantastic foundation put forth by Hari Seldon over at the [Real Day Trading](https://www.reddit.com/r/RealDayTrading/) subreddit.

This was an extremely enjoyable project, one that not only filled a need but also provided invaluable experience in assessing gen-AI agents and their ability to contribute to a project.
