#!/bin/bash
# GitHub Issues Creation Script for Reddit Sentiment Scraper
# Run this script after installing gh CLI: https://cli.github.com/
# Usage: ./create_github_issues.sh

set -e

REPO="pcjtse/reddit-sentiment-scraper"

echo "Creating GitHub issues for $REPO..."
echo "============================================"

# =============================================================================
# CRITICAL FIXES (Priority: P0)
# =============================================================================

echo "Creating Critical Fix issues..."

gh issue create --repo "$REPO" \
  --title "[P0] Add missing seaborn dependency to requirements.txt" \
  --label "bug,priority:critical" \
  --body '## Description
The `seaborn` library is imported and used in `reddit_sentiment_scraper.py` (line 126) but is not listed in `requirements.txt`.

## Impact
**Critical** - Application will crash with `ModuleNotFoundError` when `analyze_comment_sentiment()` is called.

## Steps to Reproduce
1. Create fresh virtual environment
2. Install dependencies: `pip install -r requirements.txt`
3. Run the scraper
4. Observe crash when generating comment sentiment analysis

## Suggested Fix
Add `seaborn>=0.13.0` to `requirements.txt`'

gh issue create --repo "$REPO" \
  --title "[P0] Optimize VADER sentiment analyzer initialization" \
  --label "performance,priority:critical" \
  --body '## Description
The VADER `SentimentIntensityAnalyzer` is instantiated inside the `analyze_sentiment()` function (line 56), causing it to be recreated for every single text analysis call.

## Impact
**Critical** - Significant performance degradation when analyzing thousands of posts and comments.

## Current Code
```python
def analyze_sentiment(text):
    sia = SentimentIntensityAnalyzer()  # Created every call!
    return sia.polarity_scores(text)['"'"'compound'"'"']
```

## Suggested Fix
Initialize the analyzer once at module level:
```python
sia = SentimentIntensityAnalyzer()

def analyze_sentiment(text):
    return sia.polarity_scores(text)['"'"'compound'"'"']
```'

gh issue create --repo "$REPO" \
  --title "[P0] Add error handling for Reddit API calls" \
  --label "bug,priority:critical" \
  --body '## Description
The application has no try-except blocks around Reddit API calls in `get_posts()`. API failures due to rate limits, connectivity issues, or invalid credentials cause unhandled crashes.

## Impact
**Critical** - Application crashes without meaningful error messages when API issues occur.

## Areas Needing Error Handling
- Reddit client initialization
- Subreddit search queries
- Comment fetching (`post.comments.replace_more()`)
- Individual post processing

## Suggested Implementation
Add try-except blocks with specific exception handling for:
- `praw.exceptions.APIException`
- `requests.exceptions.RequestException`
- General exceptions with logging

Also implement retry logic with exponential backoff for transient failures.'

gh issue create --repo "$REPO" \
  --title "[P0] Add environment variable validation on startup" \
  --label "bug,priority:critical" \
  --body '## Description
The application does not validate that required environment variables are set before attempting to use them. Missing or misconfigured `.env` values cause cryptic errors.

## Required Environment Variables
- `REDDIT_CLIENT_ID`
- `REDDIT_CLIENT_SECRET`
- `REDDIT_USER_AGENT`

## Impact
**Critical** - Users receive confusing error messages when credentials are missing.

## Suggested Implementation
Add a `validate_env()` function that checks for required variables and exits with a helpful message if any are missing.'

# =============================================================================
# CODE IMPROVEMENTS (Priority: P1)
# =============================================================================

echo "Creating Code Improvement issues..."

gh issue create --repo "$REPO" \
  --title "[P1] Add retry logic with exponential backoff for API calls" \
  --label "enhancement,reliability" \
  --body '## Description
Reddit API calls can fail due to transient network issues or rate limiting. The application should automatically retry failed requests.

## Suggested Implementation
```python
import time
from functools import wraps

def retry_with_backoff(max_retries=3, base_delay=2):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_retries - 1:
                        raise
                    delay = base_delay * (2 ** attempt)
                    print(f"Retry {attempt + 1}/{max_retries} after {delay}s...")
                    time.sleep(delay)
        return wrapper
    return decorator
```

## Acceptance Criteria
- [ ] Retry up to 3 times on failure
- [ ] Use exponential backoff (2s, 4s, 8s)
- [ ] Log retry attempts
- [ ] Distinguish between retryable and non-retryable errors'

gh issue create --repo "$REPO" \
  --title "[P1] Add proper logging module instead of print statements" \
  --label "enhancement,code-quality" \
  --body '## Description
Replace print statements with Python'"'"'s logging module for better debugging and production use.

## Benefits
- Configurable log levels (DEBUG, INFO, WARNING, ERROR)
- Log to file and/or console
- Timestamps and context in log messages
- Easy to disable verbose output

## Suggested Implementation
```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Usage
logger.info(f"Searching for {stock_symbol}...")
logger.debug(f"Found {len(posts)} posts")
logger.error(f"API error: {e}")
```'

gh issue create --repo "$REPO" \
  --title "[P1] Handle edge cases for empty posts and deleted comments" \
  --label "bug,data-quality" \
  --body '## Description
The application does not gracefully handle edge cases:
- Posts with no selftext (empty body)
- Deleted or removed comments
- Posts with no comments

## Current Issues
- Empty comment lists return sentiment of 0, biasing analysis
- Deleted comments may cause processing errors
- No distinction between "no data" and "neutral sentiment"

## Suggested Fixes
1. Use `None` instead of `0` for missing sentiment data
2. Filter out deleted/removed comments before analysis
3. Add data validation before processing
4. Handle `[deleted]` and `[removed]` text markers'

gh issue create --repo "$REPO" \
  --title "[P1] Add unit tests for core functions" \
  --label "testing,code-quality" \
  --body '## Description
The project has no test suite. Add pytest-based tests for core functionality.

## Test Coverage Needed
- [ ] `analyze_sentiment()` - Test various text inputs
- [ ] `get_posts()` - Mock Reddit API responses
- [ ] Visualization functions - Test with sample DataFrames
- [ ] Edge cases - Empty data, special characters, etc.

## Suggested Structure
```
tests/
  __init__.py
  test_sentiment.py
  test_data_collection.py
  test_visualizations.py
  conftest.py  # Fixtures
```

## Dependencies to Add
- pytest
- pytest-mock
- pytest-cov (for coverage reports)'

gh issue create --repo "$REPO" \
  --title "[P1] Add progress bars for long-running operations" \
  --label "enhancement,ux" \
  --body '## Description
When scraping large amounts of data, users have no visibility into progress. Add progress indicators using tqdm.

## Areas to Add Progress Bars
- Iterating through subreddits
- Processing posts
- Fetching comments
- Running sentiment analysis

## Suggested Implementation
```python
from tqdm import tqdm

for subreddit_name in tqdm(subreddits, desc="Searching subreddits"):
    # ...

for post in tqdm(posts, desc="Analyzing posts"):
    # ...
```

## Dependency
Add `tqdm>=4.66.0` to requirements.txt'

# =============================================================================
# HIGH VALUE FEATURES (Priority: P2)
# =============================================================================

echo "Creating High Value Feature issues..."

gh issue create --repo "$REPO" \
  --title "[P2] Add CLI arguments support" \
  --label "enhancement,feature" \
  --body '## Description
Add command-line argument support instead of only interactive input.

## Proposed Arguments
```
python reddit_sentiment_scraper.py --symbol AAPL --days 14 --subreddits wallstreetbets,stocks
python reddit_sentiment_scraper.py -s TSLA -d 7 --output results.json
python reddit_sentiment_scraper.py --help
```

## Arguments to Support
| Argument | Short | Description | Default |
|----------|-------|-------------|---------|
| --symbol | -s | Stock symbol to analyze | (required) |
| --days | -d | Number of days to look back | 7 |
| --subreddits | -r | Comma-separated subreddit list | wallstreetbets,stocks,investing |
| --output | -o | Output file path | None (display only) |
| --format | -f | Output format (json/csv/html) | json |
| --quiet | -q | Suppress visualization display | False |

## Suggested Library
Use `argparse` (stdlib) or `click` for more advanced features.'

gh issue create --repo "$REPO" \
  --title "[P2] Add export functionality (CSV/JSON/HTML)" \
  --label "enhancement,feature" \
  --body '## Description
Allow users to export analysis results to various formats for further processing or reporting.

## Export Formats
1. **JSON** - Full data with metadata
2. **CSV** - Tabular data for spreadsheets
3. **HTML** - Formatted report with embedded charts

## Data to Export
- Raw post data with sentiment scores
- Aggregated statistics
- Visualization images (base64 or separate files)
- Analysis metadata (date range, stock symbol, etc.)

## Suggested Implementation
```python
def export_results(df, stats, format="json", output_path=None):
    if format == "json":
        export_json(df, stats, output_path)
    elif format == "csv":
        export_csv(df, output_path)
    elif format == "html":
        export_html(df, stats, output_path)
```'

gh issue create --repo "$REPO" \
  --title "[P2] Make subreddits configurable" \
  --label "enhancement,feature" \
  --body '## Description
Currently, the subreddit list is hardcoded. Allow users to configure which subreddits to search.

## Configuration Options
1. Command-line argument: `--subreddits wsb,stocks,options`
2. Environment variable: `REDDIT_SUBREDDITS=wsb,stocks,options`
3. Config file: `config.yaml` or `config.json`

## Default Subreddits
Keep current defaults but allow override:
- wallstreetbets
- stocks
- investing

## Additional Subreddits to Consider
- options
- stockmarket
- pennystocks
- dividends
- SecurityAnalysis'

gh issue create --repo "$REPO" \
  --title "[P2] Add caching layer for API results" \
  --label "enhancement,performance" \
  --body '## Description
Cache Reddit API results to:
- Avoid redundant API calls
- Enable offline analysis
- Speed up repeated analyses
- Reduce rate limit issues

## Suggested Implementation
```python
import hashlib
import json
from pathlib import Path

CACHE_DIR = Path(".cache")

def get_cache_key(symbol, days, subreddits):
    key = f"{symbol}_{days}_{'"'"','"'"'.join(sorted(subreddits))}"
    return hashlib.md5(key.encode()).hexdigest()

def load_from_cache(cache_key, max_age_hours=1):
    cache_file = CACHE_DIR / f"{cache_key}.json"
    if cache_file.exists():
        # Check age and return if fresh
        pass
    return None

def save_to_cache(cache_key, data):
    CACHE_DIR.mkdir(exist_ok=True)
    cache_file = CACHE_DIR / f"{cache_key}.json"
    cache_file.write_text(json.dumps(data))
```

## Cache Invalidation
- Time-based expiry (default: 1 hour)
- Manual clear option: `--clear-cache`
- Bypass option: `--no-cache`'

gh issue create --repo "$REPO" \
  --title "[P2] Support multiple stock comparison" \
  --label "enhancement,feature" \
  --body '## Description
Allow analyzing and comparing sentiment for multiple stocks simultaneously.

## Use Cases
- Compare sentiment between competitors (AAPL vs MSFT)
- Track sector sentiment (multiple tech stocks)
- Portfolio sentiment overview

## Proposed Interface
```
python reddit_sentiment_scraper.py --symbols AAPL,MSFT,GOOGL --compare
```

## Comparison Visualizations
- Side-by-side sentiment trends
- Comparative bar charts
- Correlation matrix between stocks
- Relative mention frequency

## Implementation Considerations
- Run analyses in parallel for performance
- Normalize data for fair comparison
- Handle stocks with very different mention volumes'

# =============================================================================
# ANALYSIS ENHANCEMENTS (Priority: P2)
# =============================================================================

echo "Creating Analysis Enhancement issues..."

gh issue create --repo "$REPO" \
  --title "[P2] Add historical trend tracking with database storage" \
  --label "enhancement,feature" \
  --body '## Description
Store analysis results over time to track sentiment changes and identify trends.

## Database Options
1. **SQLite** - Simple, no server needed, good for local use
2. **PostgreSQL** - Better for production/multi-user
3. **InfluxDB** - Optimized for time-series data

## Schema Design
```sql
CREATE TABLE sentiment_records (
    id INTEGER PRIMARY KEY,
    symbol VARCHAR(10),
    date DATE,
    avg_sentiment FLOAT,
    post_count INTEGER,
    comment_count INTEGER,
    subreddit VARCHAR(50),
    created_at TIMESTAMP
);
```

## Features
- Daily sentiment snapshots
- Week-over-week comparisons
- Trend detection algorithms
- Anomaly detection (unusual sentiment spikes)'

gh issue create --repo "$REPO" \
  --title "[P2] Add stock price correlation analysis" \
  --label "enhancement,feature,analytics" \
  --body '## Description
Compare Reddit sentiment with actual stock price movements to evaluate predictive value.

## Data Sources
- Yahoo Finance API (yfinance library)
- Alpha Vantage
- Polygon.io

## Analysis Features
- Sentiment vs price correlation coefficient
- Lead/lag analysis (does sentiment predict price?)
- Sentiment divergence detection
- Volume-weighted sentiment

## Visualization
- Dual-axis chart: sentiment + price over time
- Scatter plot: sentiment vs next-day returns
- Correlation heatmap by time lag

## Dependencies
Add `yfinance>=0.2.0` to requirements.txt'

gh issue create --repo "$REPO" \
  --title "[P2] Add entity extraction for co-mentioned stocks" \
  --label "enhancement,feature,nlp" \
  --body '## Description
Identify other stock tickers and companies mentioned alongside the target stock.

## Use Cases
- Discover related investment opportunities
- Understand market sector context
- Track competitor mentions

## Implementation
```python
import re

def extract_tickers(text):
    # Match $AAPL style mentions
    cashtags = re.findall(r'"'"'\$([A-Z]{1,5})\b'"'"', text)
    # Match standalone tickers (with validation against known list)
    return list(set(cashtags))
```

## Features
- Co-mention frequency analysis
- Sentiment comparison for co-mentioned stocks
- Network graph of related stocks
- Trending tickers detection'

gh issue create --repo "$REPO" \
  --title "[P2] Add author reputation analysis" \
  --label "enhancement,feature,analytics" \
  --body '## Description
Weight sentiment analysis by author credibility metrics.

## Metrics to Consider
- Account age
- Total karma
- Subreddit-specific karma
- Post history in financial subreddits
- Historical prediction accuracy (if trackable)

## Implementation
```python
def get_author_weight(author):
    if author is None:
        return 0.5  # Deleted accounts

    karma_score = min(author.link_karma + author.comment_karma, 100000) / 100000
    age_days = (datetime.now() - datetime.fromtimestamp(author.created_utc)).days
    age_score = min(age_days, 365) / 365

    return (karma_score + age_score) / 2
```

## Weighted Sentiment
`weighted_sentiment = sentiment * author_weight`'

gh issue create --repo "$REPO" \
  --title "[P2] Add engagement-weighted sentiment analysis" \
  --label "enhancement,feature,analytics" \
  --body '## Description
Weight sentiment scores by post engagement metrics to prioritize influential content.

## Engagement Metrics
- Upvotes/score
- Number of comments
- Awards received
- Upvote ratio

## Weighting Formula
```python
def calculate_engagement_weight(post):
    score_weight = np.log1p(post.score) / 10  # Log scale for scores
    comment_weight = np.log1p(post.num_comments) / 5
    award_weight = len(post.all_awardings) * 0.1

    return min(score_weight + comment_weight + award_weight, 1.0)

weighted_sentiment = base_sentiment * engagement_weight
```

## Benefits
- Reduces noise from low-engagement posts
- Highlights community consensus
- Better reflects actual market sentiment'

# =============================================================================
# VISUALIZATION IMPROVEMENTS (Priority: P3)
# =============================================================================

echo "Creating Visualization Improvement issues..."

gh issue create --repo "$REPO" \
  --title "[P3] Add interactive dashboards with Plotly/Dash" \
  --label "enhancement,visualization" \
  --body '## Description
Replace static matplotlib charts with interactive Plotly visualizations or a full Dash dashboard.

## Benefits
- Zoom, pan, and hover for details
- Interactive filtering
- Web-based sharing
- Real-time updates

## Dashboard Components
- Sentiment trend with date range selector
- Filterable post table
- Interactive word cloud
- Drill-down by subreddit

## Implementation Options
1. **Plotly Express** - Quick interactive charts
2. **Dash** - Full web dashboard
3. **Streamlit** - Rapid prototyping

## Dependencies
- plotly>=5.18.0
- dash>=2.14.0 (optional)'

gh issue create --repo "$REPO" \
  --title "[P3] Add sentiment heatmap visualization" \
  --label "enhancement,visualization" \
  --body '## Description
Create a heatmap showing sentiment patterns by time of day and day of week.

## Visualization
```
        Mon   Tue   Wed   Thu   Fri   Sat   Sun
00:00   0.2   0.1   0.3   0.2   0.4   0.1   0.0
04:00   0.1   0.2   0.1   0.3   0.2   0.2   0.1
08:00   0.4   0.5   0.3   0.4   0.6   0.3   0.2
12:00   0.3   0.4   0.5   0.4   0.5   0.4   0.3
...
```

## Implementation
```python
import seaborn as sns

def create_sentiment_heatmap(df):
    df['"'"'hour'"'"'] = df['"'"'created_utc'"'"'].dt.hour
    df['"'"'dayofweek'"'"'] = df['"'"'created_utc'"'"'].dt.dayofweek

    pivot = df.pivot_table(
        values='"'"'sentiment'"'"',
        index='"'"'hour'"'"',
        columns='"'"'dayofweek'"'"',
        aggfunc='"'"'mean'"'"'
    )

    sns.heatmap(pivot, cmap='"'"'RdYlGn'"'"', center=0)
```

## Insights
- Identify optimal posting times
- Detect day-of-week sentiment patterns
- Find unusual activity periods'

gh issue create --repo "$REPO" \
  --title "[P3] Add stock mention network graph" \
  --label "enhancement,visualization" \
  --body '## Description
Visualize relationships between frequently co-mentioned stocks using a network graph.

## Implementation
```python
import networkx as nx
import matplotlib.pyplot as plt

def create_mention_network(df, target_symbol):
    G = nx.Graph()
    G.add_node(target_symbol, size=100)

    # Add co-mentioned stocks as nodes
    for _, row in df.iterrows():
        co_mentions = extract_tickers(row['"'"'text'"'"'])
        for ticker in co_mentions:
            if ticker != target_symbol:
                if G.has_edge(target_symbol, ticker):
                    G[target_symbol][ticker]['"'"'weight'"'"'] += 1
                else:
                    G.add_edge(target_symbol, ticker, weight=1)

    # Draw network
    pos = nx.spring_layout(G)
    nx.draw(G, pos, with_labels=True, node_size=[G.nodes[n].get('"'"'size'"'"', 50) for n in G.nodes()])
```

## Dependencies
Add `networkx>=3.2.0` to requirements.txt'

# =============================================================================
# ADVANCED NLP FEATURES (Priority: P3)
# =============================================================================

echo "Creating Advanced NLP Feature issues..."

gh issue create --repo "$REPO" \
  --title "[P3] Implement financial-specific sentiment analysis (FinBERT)" \
  --label "enhancement,nlp,feature" \
  --body '## Description
VADER is designed for general social media text. Financial text has domain-specific language that FinBERT handles better.

## Why FinBERT?
- Trained on financial news and reports
- Understands financial terminology
- Better accuracy for investment sentiment
- Handles negation and context better

## Implementation
```python
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch

tokenizer = AutoTokenizer.from_pretrained("ProsusAI/finbert")
model = AutoModelForSequenceClassification.from_pretrained("ProsusAI/finbert")

def analyze_sentiment_finbert(text):
    inputs = tokenizer(text, return_tensors="pt", truncation=True, max_length=512)
    outputs = model(**inputs)
    probabilities = torch.softmax(outputs.logits, dim=1)
    # Returns: negative, neutral, positive
    return probabilities.tolist()[0]
```

## Considerations
- Requires GPU for reasonable performance
- Larger model size (~500MB)
- May need batching for large datasets
- Consider hybrid approach: VADER for speed, FinBERT for accuracy'

gh issue create --repo "$REPO" \
  --title "[P3] Add sarcasm and irony detection" \
  --label "enhancement,nlp,feature" \
  --body '## Description
Reddit, especially WSB, is heavy on sarcasm and irony. Posts like "Great job losing money!" should not be classified as positive.

## Approaches
1. **Rule-based markers**
   - Detect /s tags
   - Identify common sarcastic phrases
   - Look for sentiment-emoji mismatches

2. **ML-based detection**
   - Fine-tuned BERT for sarcasm
   - Use existing sarcasm detection models

## Implementation Sketch
```python
SARCASM_MARKERS = ["/s", "sure jan", "totally", "definitely not"]

def detect_sarcasm(text):
    text_lower = text.lower()

    # Check explicit markers
    if any(marker in text_lower for marker in SARCASM_MARKERS):
        return True

    # Check for emoji/text sentiment mismatch
    # ... more sophisticated detection

    return False

def adjusted_sentiment(text):
    base_sentiment = analyze_sentiment(text)
    if detect_sarcasm(text):
        return -base_sentiment  # Invert sentiment
    return base_sentiment
```'

gh issue create --repo "$REPO" \
  --title "[P3] Add emoji sentiment analysis" \
  --label "enhancement,nlp,feature" \
  --body '## Description
Reddit financial communities use emojis with specific meanings that VADER may not capture correctly.

## Common Financial Emojis
| Emoji | Meaning | Sentiment |
|-------|---------|-----------|
| :rocket: | To the moon / bullish | Very positive |
| :gem::raised_hands: | Diamond hands / holding | Positive |
| :bear: | Bearish | Negative |
| :chart_with_upwards_trend: | Bullish | Positive |
| :chart_with_downwards_trend: | Bearish | Negative |
| :clown_face: | Bad decision | Negative |
| :fire: | Hot stock / burning money | Context-dependent |

## Implementation
```python
import emoji

EMOJI_SENTIMENT = {
    "🚀": 0.8,
    "💎": 0.6,
    "🙌": 0.4,
    "📈": 0.5,
    "📉": -0.5,
    "🐻": -0.6,
    "🐂": 0.6,
    "🤡": -0.4,
    "💀": -0.3,
}

def analyze_emoji_sentiment(text):
    emojis = emoji.emoji_list(text)
    if not emojis:
        return 0

    scores = [EMOJI_SENTIMENT.get(e['"'"'emoji'"'"'], 0) for e in emojis]
    return sum(scores) / len(scores) if scores else 0
```'

gh issue create --repo "$REPO" \
  --title "[P3] Add keyword spike alerts and monitoring" \
  --label "enhancement,feature" \
  --body '## Description
Monitor for unusual spikes in specific keywords that might indicate important market events.

## Keywords to Track
- squeeze, short squeeze
- moon, mooning
- crash, dump
- DD (due diligence)
- YOLO
- calls, puts
- earnings, ER

## Alert Conditions
- Keyword frequency > 2x normal
- Sentiment shift > 0.3 in 24 hours
- Unusual posting volume
- New stock gaining mentions

## Implementation
```python
from collections import Counter
from datetime import datetime, timedelta

def detect_keyword_spikes(df, baseline_days=7, threshold=2.0):
    now = datetime.now()
    recent = df[df['"'"'created_utc'"'"'] > now - timedelta(days=1)]
    baseline = df[df['"'"'created_utc'"'"'] > now - timedelta(days=baseline_days)]

    recent_counts = Counter(extract_keywords(recent['"'"'text'"'"']))
    baseline_counts = Counter(extract_keywords(baseline['"'"'text'"'"']))

    spikes = []
    for keyword, count in recent_counts.items():
        baseline_rate = baseline_counts.get(keyword, 1) / baseline_days
        if count > baseline_rate * threshold:
            spikes.append((keyword, count, baseline_rate))

    return spikes
```'

# =============================================================================
# PRODUCTION FEATURES (Priority: P3)
# =============================================================================

echo "Creating Production Feature issues..."

gh issue create --repo "$REPO" \
  --title "[P3] Add scheduled analysis runs (cron/scheduler)" \
  --label "enhancement,feature,infrastructure" \
  --body '## Description
Enable automated periodic analysis runs for continuous sentiment monitoring.

## Options
1. **Cron job** - Simple, Unix-based
2. **APScheduler** - Python-native scheduling
3. **Celery** - Distributed task queue
4. **GitHub Actions** - CI/CD based scheduling

## APScheduler Implementation
```python
from apscheduler.schedulers.blocking import BlockingScheduler

def scheduled_analysis():
    symbols = ["AAPL", "TSLA", "GME"]
    for symbol in symbols:
        run_analysis(symbol)
        save_results_to_db(symbol)

scheduler = BlockingScheduler()
scheduler.add_job(scheduled_analysis, '"'"'cron'"'"', hour=9, minute=0)  # Run at 9 AM
scheduler.start()
```

## GitHub Actions Example
```yaml
on:
  schedule:
    - cron: '"'"'0 9 * * *'"'"'  # Daily at 9 AM UTC
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: python reddit_sentiment_scraper.py --symbol AAPL --output results/
```'

gh issue create --repo "$REPO" \
  --title "[P3] Add database storage for historical data" \
  --label "enhancement,feature,infrastructure" \
  --body '## Description
Implement persistent storage for analysis results to enable historical tracking and trend analysis.

## Database Options

### SQLite (Recommended for start)
```python
import sqlite3

def init_db():
    conn = sqlite3.connect('"'"'sentiment_data.db'"'"')
    conn.execute('"'"''"'"''"'"'
        CREATE TABLE IF NOT EXISTS analyses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            symbol TEXT NOT NULL,
            analysis_date DATE NOT NULL,
            avg_sentiment REAL,
            post_count INTEGER,
            top_posts TEXT,  -- JSON
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    '"'"''"'"''"'"')
    return conn
```

### PostgreSQL (For production)
- Better concurrency
- More data types
- Better for multi-user access

## Features
- Store daily snapshots
- Query historical trends
- Compare across time periods
- Generate reports from stored data'

gh issue create --repo "$REPO" \
  --title "[P3] Expose analysis as REST API" \
  --label "enhancement,feature,infrastructure" \
  --body '## Description
Create a REST API to expose sentiment analysis functionality for integration with other tools.

## Endpoints
```
GET  /api/v1/sentiment/{symbol}
POST /api/v1/sentiment/analyze
GET  /api/v1/sentiment/{symbol}/history
GET  /api/v1/trending
```

## FastAPI Implementation
```python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class AnalysisRequest(BaseModel):
    symbol: str
    days: int = 7
    subreddits: list[str] = ["wallstreetbets", "stocks"]

@app.get("/api/v1/sentiment/{symbol}")
async def get_sentiment(symbol: str, days: int = 7):
    results = run_analysis(symbol, days)
    return {
        "symbol": symbol,
        "sentiment": results["avg_sentiment"],
        "post_count": results["post_count"],
        "trend": results["trend"]
    }
```

## Dependencies
- fastapi>=0.109.0
- uvicorn>=0.27.0'

gh issue create --repo "$REPO" \
  --title "[P3] Add Reddit API rate limit handling" \
  --label "enhancement,reliability" \
  --body '## Description
Implement proper rate limit awareness and handling for Reddit API calls.

## Reddit API Limits
- 60 requests per minute for OAuth
- 30 requests per minute for script apps
- Requests that exceed limits receive 429 responses

## Implementation
```python
import time
from prawcore.exceptions import TooManyRequests

class RateLimitedReddit:
    def __init__(self, reddit):
        self.reddit = reddit
        self.min_request_interval = 1.0  # seconds
        self.last_request = 0

    def search(self, *args, **kwargs):
        self._wait_if_needed()
        try:
            return self.reddit.subreddit(*args).search(**kwargs)
        except TooManyRequests as e:
            wait_time = int(e.response.headers.get('"'"'retry-after'"'"', 60))
            print(f"Rate limited. Waiting {wait_time}s...")
            time.sleep(wait_time)
            return self.search(*args, **kwargs)

    def _wait_if_needed(self):
        elapsed = time.time() - self.last_request
        if elapsed < self.min_request_interval:
            time.sleep(self.min_request_interval - elapsed)
        self.last_request = time.time()
```

## Features
- Pre-emptive rate limiting
- Automatic retry on 429 responses
- Respect Retry-After headers
- Request queuing for burst protection'

echo ""
echo "============================================"
echo "All issues created successfully!"
echo "View issues at: https://github.com/$REPO/issues"
