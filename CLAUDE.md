# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Reddit Stock Sentiment Scraper - A Python tool that analyzes sentiment from Reddit discussions about stocks. Two interfaces:
- **CLI tool** (`reddit_sentiment_scraper.py`): Interactive script with matplotlib visualizations
- **Web UI** (`app.py`): Flask app with treemap heatmap visualization

## Commands

### Install dependencies
```bash
pip install -r requirements.txt
```

### Run CLI sentiment analyzer
```bash
python reddit_sentiment_scraper.py
# Prompts for stock symbol (e.g., AAPL)
```

### Run web UI
```bash
python app.py
# Opens at http://localhost:5000
```

## Architecture

### Two Entry Points

1. **reddit_sentiment_scraper.py** - CLI tool
   - Fetches posts from subreddits (wallstreetbets, stocks, investing) for a single symbol
   - Uses VADER sentiment analysis via NLTK
   - Generates 7 matplotlib visualizations: sentiment trend, word cloud, post volume, subreddit distribution, top posts, comment sentiment, time distribution
   - Performance note: VADER analyzer is recreated per call in `analyze_sentiment()` (line 56)

2. **app.py** - Flask web UI
   - Treemap visualization where color = sentiment, size = market cap
   - Analyzes multiple symbols in parallel via `ThreadPoolExecutor`
   - Falls back to demo data when Reddit API unavailable
   - Uses yfinance for market cap data
   - Single VADER analyzer instance (line 39) for better performance

### Key Differences Between Interfaces

| Feature | CLI | Web UI |
|---------|-----|--------|
| Symbols | Single | Multiple (up to 20) |
| Market cap | No | Yes (via yfinance) |
| Comments | Fetched & analyzed | Not fetched |
| Demo mode | No | Yes |
| Error handling | Minimal | Full try/except |

### External Dependencies

- **Reddit API** (PRAW): Requires `REDDIT_CLIENT_ID`, `REDDIT_CLIENT_SECRET`, `REDDIT_USER_AGENT` in `.env`
- **yfinance**: Stock market data (web UI only)
- **NLTK VADER**: Sentiment analysis (auto-downloads `vader_lexicon`)

## Environment Variables

Required in `.env` file:
```
REDDIT_CLIENT_ID=your_client_id
REDDIT_CLIENT_SECRET=your_client_secret
REDDIT_USER_AGENT=your_user_agent
```

Get credentials at https://www.reddit.com/prefs/apps (create "script" type app)
