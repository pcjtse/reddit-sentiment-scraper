# Reddit Sentiment Scraper - Improvement Issues

This document contains all suggested improvements organized by priority.

## Priority Levels
- **P0 - Critical**: Must fix before production use
- **P1 - High**: Important improvements for reliability/quality
- **P2 - Medium**: Valuable features to add
- **P3 - Low**: Nice-to-have enhancements

---

## P0 - Critical Fixes

### 1. Add missing seaborn dependency to requirements.txt
**Type:** Bug

The `seaborn` library is imported and used in `reddit_sentiment_scraper.py` (line 126) but is not listed in `requirements.txt`.

**Impact:** Application will crash with `ModuleNotFoundError` when `analyze_comment_sentiment()` is called.

**Fix:** Add `seaborn>=0.13.0` to `requirements.txt`

---

### 2. Optimize VADER sentiment analyzer initialization
**Type:** Performance

The VADER `SentimentIntensityAnalyzer` is instantiated inside the `analyze_sentiment()` function (line 56), causing it to be recreated for every single text analysis call.

**Impact:** Significant performance degradation when analyzing thousands of posts and comments.

**Fix:** Initialize the analyzer once at module level.

---

### 3. Add error handling for Reddit API calls
**Type:** Bug

The application has no try-except blocks around Reddit API calls in `get_posts()`. API failures due to rate limits, connectivity issues, or invalid credentials cause unhandled crashes.

**Impact:** Application crashes without meaningful error messages when API issues occur.

---

### 4. Add environment variable validation on startup
**Type:** Bug

The application does not validate that required environment variables are set before attempting to use them.

**Required Variables:**
- `REDDIT_CLIENT_ID`
- `REDDIT_CLIENT_SECRET`
- `REDDIT_USER_AGENT`

---

## P1 - Code Improvements

### 5. Add retry logic with exponential backoff for API calls
**Type:** Reliability

Implement automatic retry for failed Reddit API requests with exponential backoff (2s, 4s, 8s).

---

### 6. Add proper logging module instead of print statements
**Type:** Code Quality

Replace print statements with Python's logging module for configurable log levels, file output, and timestamps.

---

### 7. Handle edge cases for empty posts and deleted comments
**Type:** Data Quality

- Posts with no selftext
- Deleted or removed comments
- Posts with no comments
- Use `None` instead of `0` for missing sentiment

---

### 8. Add unit tests for core functions
**Type:** Testing

Add pytest-based tests for:
- `analyze_sentiment()`
- `get_posts()`
- Visualization functions
- Edge cases

---

### 9. Add progress bars for long-running operations
**Type:** UX

Use `tqdm` to show progress when:
- Iterating through subreddits
- Processing posts
- Fetching comments

---

## P2 - High Value Features

### 10. Add CLI arguments support
**Type:** Feature

Support command-line arguments:
```bash
python reddit_sentiment_scraper.py --symbol AAPL --days 14 --subreddits wallstreetbets,stocks
```

Arguments: `--symbol`, `--days`, `--subreddits`, `--output`, `--format`, `--quiet`

---

### 11. Add export functionality (CSV/JSON/HTML)
**Type:** Feature

Export analysis results to:
- JSON - Full data with metadata
- CSV - Tabular data for spreadsheets
- HTML - Formatted report with embedded charts

---

### 12. Make subreddits configurable
**Type:** Feature

Allow users to configure subreddits via:
- Command-line argument
- Environment variable
- Config file

---

### 13. Add caching layer for API results
**Type:** Performance

Cache Reddit API results to:
- Avoid redundant API calls
- Enable offline analysis
- Speed up repeated analyses
- Reduce rate limit issues

---

### 14. Support multiple stock comparison
**Type:** Feature

Analyze and compare sentiment for multiple stocks:
```bash
python reddit_sentiment_scraper.py --symbols AAPL,MSFT,GOOGL --compare
```

---

## P2 - Analysis Enhancements

### 15. Add historical trend tracking with database storage
**Type:** Feature

Store analysis results over time to track sentiment changes using SQLite or PostgreSQL.

---

### 16. Add stock price correlation analysis
**Type:** Analytics

Compare Reddit sentiment with actual stock price movements using yfinance.

---

### 17. Add entity extraction for co-mentioned stocks
**Type:** NLP

Identify other stock tickers mentioned alongside the target stock.

---

### 18. Add author reputation analysis
**Type:** Analytics

Weight sentiment by author credibility (karma, account age, history).

---

### 19. Add engagement-weighted sentiment analysis
**Type:** Analytics

Weight sentiment scores by post engagement (upvotes, comments, awards).

---

## P3 - Visualization Improvements

### 20. Add interactive dashboards with Plotly/Dash
**Type:** Visualization

Replace static matplotlib charts with interactive Plotly visualizations.

---

### 21. Add sentiment heatmap visualization
**Type:** Visualization

Create heatmap showing sentiment patterns by time of day and day of week.

---

### 22. Add stock mention network graph
**Type:** Visualization

Visualize relationships between frequently co-mentioned stocks using networkx.

---

## P3 - Advanced NLP Features

### 23. Implement financial-specific sentiment analysis (FinBERT)
**Type:** NLP

Use FinBERT instead of VADER for better accuracy on financial text.

---

### 24. Add sarcasm and irony detection
**Type:** NLP

Detect sarcasm (common in WSB) to avoid sentiment misclassification.

---

### 25. Add emoji sentiment analysis
**Type:** NLP

Handle Reddit financial emojis with specific meanings (🚀, 💎🙌, 🐻, etc.).

---

### 26. Add keyword spike alerts and monitoring
**Type:** Feature

Monitor for unusual spikes in keywords like "squeeze", "moon", "crash".

---

## P3 - Production Features

### 27. Add scheduled analysis runs (cron/scheduler)
**Type:** Infrastructure

Enable automated periodic analysis using APScheduler or GitHub Actions.

---

### 28. Add database storage for historical data
**Type:** Infrastructure

Implement persistent storage using SQLite or PostgreSQL.

---

### 29. Expose analysis as REST API
**Type:** Infrastructure

Create FastAPI endpoints for integration with other tools.

---

### 30. Add Reddit API rate limit handling
**Type:** Reliability

Implement proper rate limit awareness with pre-emptive limiting and retry logic.

---

## Quick Start

To create these issues on GitHub, install the [GitHub CLI](https://cli.github.com/) and run:

```bash
chmod +x create_github_issues.sh
./create_github_issues.sh
```

Or create issues manually using the GitHub web interface.
