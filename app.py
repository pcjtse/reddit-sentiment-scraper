"""
Reddit Sentiment Scraper - Web UI
A Flask web application that displays a treemap heatmap of stock sentiments.
- Color represents sentiment (red = negative, green = positive)
- Size represents market capitalization
"""

import os
import json
import logging
from datetime import datetime, timedelta
from concurrent.futures import ThreadPoolExecutor, as_completed

import praw
import pandas as pd
import yfinance as yf
from flask import Flask, render_template, request, jsonify
from nltk.sentiment import SentimentIntensityAnalyzer
import nltk
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Download required NLTK data
nltk.download('vader_lexicon', quiet=True)

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)

# Initialize sentiment analyzer once (performance optimization)
sia = SentimentIntensityAnalyzer()

# Initialize Reddit client
def get_reddit_client():
    """Create and return Reddit client with error handling."""
    client_id = os.getenv('REDDIT_CLIENT_ID')
    client_secret = os.getenv('REDDIT_CLIENT_SECRET')
    user_agent = os.getenv('REDDIT_USER_AGENT')

    if not all([client_id, client_secret, user_agent]):
        logger.warning("Reddit credentials not configured. Using demo mode.")
        return None

    try:
        return praw.Reddit(
            client_id=client_id,
            client_secret=client_secret,
            user_agent=user_agent
        )
    except Exception as e:
        logger.error(f"Failed to initialize Reddit client: {e}")
        return None

reddit = get_reddit_client()

# Stock-related subreddits
SUBREDDITS = ['wallstreetbets', 'stocks', 'investing']

# Default stock symbols for quick analysis
DEFAULT_SYMBOLS = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'META', 'NVDA', 'JPM', 'V', 'JNJ']


def analyze_sentiment(text):
    """Perform sentiment analysis on text using VADER."""
    if not text or not isinstance(text, str):
        return 0.0
    try:
        return sia.polarity_scores(text)['compound']
    except Exception:
        return 0.0


def get_market_cap(symbol):
    """Fetch market capitalization for a stock symbol using yfinance."""
    try:
        ticker = yf.Ticker(symbol)
        info = ticker.info
        market_cap = info.get('marketCap', 0)
        if market_cap:
            return market_cap
        # Fallback: try to calculate from shares outstanding and price
        shares = info.get('sharesOutstanding', 0)
        price = info.get('currentPrice') or info.get('regularMarketPrice', 0)
        return shares * price if shares and price else 0
    except Exception as e:
        logger.warning(f"Failed to get market cap for {symbol}: {e}")
        return 0


def get_stock_info(symbol):
    """Fetch stock information including name and market cap."""
    try:
        ticker = yf.Ticker(symbol)
        info = ticker.info
        return {
            'symbol': symbol,
            'name': info.get('shortName') or info.get('longName') or symbol,
            'market_cap': info.get('marketCap', 0),
            'price': info.get('currentPrice') or info.get('regularMarketPrice', 0),
            'sector': info.get('sector', 'Unknown'),
            'industry': info.get('industry', 'Unknown')
        }
    except Exception as e:
        logger.warning(f"Failed to get stock info for {symbol}: {e}")
        return {
            'symbol': symbol,
            'name': symbol,
            'market_cap': 0,
            'price': 0,
            'sector': 'Unknown',
            'industry': 'Unknown'
        }


def get_posts_for_symbol(symbol, days=7):
    """Fetch Reddit posts for a single stock symbol."""
    if reddit is None:
        return []

    posts = []
    cutoff_date = datetime.utcnow() - timedelta(days=days)

    try:
        for subreddit_name in SUBREDDITS:
            try:
                subreddit = reddit.subreddit(subreddit_name)
                for post in subreddit.search(symbol, time_filter='week', limit=50):
                    if datetime.fromtimestamp(post.created_utc) >= cutoff_date:
                        posts.append({
                            'title': post.title,
                            'text': post.selftext or '',
                            'score': post.score,
                            'created_utc': datetime.fromtimestamp(post.created_utc),
                            'subreddit': subreddit_name,
                            'num_comments': post.num_comments
                        })
            except Exception as e:
                logger.warning(f"Error fetching from r/{subreddit_name} for {symbol}: {e}")
                continue
    except Exception as e:
        logger.error(f"Error fetching posts for {symbol}: {e}")

    return posts


def analyze_symbol(symbol):
    """Analyze sentiment for a single stock symbol using real Reddit data."""
    logger.info(f"Analyzing {symbol}...")

    # Check if Reddit API is configured
    if reddit is None:
        logger.warning(f"Cannot analyze {symbol}: Reddit API not configured")
        return None

    # Get stock info (market cap, name, etc.)
    stock_info = get_stock_info(symbol)

    # Get Reddit posts
    posts = get_posts_for_symbol(symbol)

    if not posts:
        logger.info(f"No Reddit posts found for {symbol}")
        return {
            'symbol': symbol,
            'name': stock_info['name'],
            'sentiment': 0.0,
            'post_count': 0,
            'market_cap': stock_info['market_cap'],
            'sector': stock_info['sector'],
            'avg_score': 0,
            'no_data': True
        }

    # Calculate sentiment from real Reddit posts
    sentiments = []
    total_score = 0

    for post in posts:
        text = f"{post['title']} {post['text']}"
        sentiment = analyze_sentiment(text)
        sentiments.append(sentiment)
        total_score += post['score']

    avg_sentiment = sum(sentiments) / len(sentiments) if sentiments else 0
    avg_score = total_score / len(posts) if posts else 0

    logger.info(f"Analyzed {symbol}: {len(posts)} posts, sentiment={avg_sentiment:.3f}")

    return {
        'symbol': symbol,
        'name': stock_info['name'],
        'sentiment': round(avg_sentiment, 3),
        'post_count': len(posts),
        'market_cap': stock_info['market_cap'],
        'sector': stock_info['sector'],
        'avg_score': round(avg_score, 1),
        'no_data': False
    }


def analyze_symbols_parallel(symbols, max_workers=5):
    """Analyze multiple symbols in parallel."""
    results = []

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_symbol = {executor.submit(analyze_symbol, symbol): symbol for symbol in symbols}

        for future in as_completed(future_to_symbol):
            symbol = future_to_symbol[future]
            try:
                result = future.result()
                if result:
                    results.append(result)
            except Exception as e:
                logger.error(f"Error analyzing {symbol}: {e}")

    return results


def format_market_cap(value):
    """Format market cap for display."""
    if value >= 1e12:
        return f"${value/1e12:.2f}T"
    elif value >= 1e9:
        return f"${value/1e9:.2f}B"
    elif value >= 1e6:
        return f"${value/1e6:.2f}M"
    else:
        return f"${value:,.0f}"


@app.route('/')
def index():
    """Render the main page."""
    return render_template('index.html', default_symbols=','.join(DEFAULT_SYMBOLS))


@app.route('/api/analyze', methods=['POST'])
def api_analyze():
    """API endpoint to analyze stock symbols using real Reddit data."""
    # Check if Reddit API is configured
    if reddit is None:
        return jsonify({
            'error': 'Reddit API not configured. Please set REDDIT_CLIENT_ID, REDDIT_CLIENT_SECRET, and REDDIT_USER_AGENT environment variables.',
            'setup_required': True
        }), 503

    data = request.get_json()
    symbols_input = data.get('symbols', '')

    # Parse symbols
    symbols = [s.strip().upper() for s in symbols_input.split(',') if s.strip()]

    if not symbols:
        return jsonify({'error': 'No symbols provided'}), 400

    if len(symbols) > 20:
        return jsonify({'error': 'Maximum 20 symbols allowed'}), 400

    logger.info(f"Analyzing symbols: {symbols}")

    # Analyze symbols using real Reddit data
    results = analyze_symbols_parallel(symbols)

    if not results:
        return jsonify({'error': 'No data found for provided symbols'}), 404

    # Prepare treemap data
    treemap_data = []
    for r in results:
        if r['market_cap'] > 0:  # Only include stocks with valid market cap
            treemap_data.append({
                'symbol': r['symbol'],
                'name': r['name'],
                'sentiment': r['sentiment'],
                'sentiment_label': 'Bullish' if r['sentiment'] > 0.1 else ('Bearish' if r['sentiment'] < -0.1 else 'Neutral'),
                'post_count': r['post_count'],
                'market_cap': r['market_cap'],
                'market_cap_formatted': format_market_cap(r['market_cap']),
                'sector': r['sector'],
                'avg_score': r['avg_score'],
                'no_data': r.get('no_data', False)
            })

    # Sort by market cap for consistent ordering
    treemap_data.sort(key=lambda x: x['market_cap'], reverse=True)

    # Calculate summary statistics
    if treemap_data:
        avg_sentiment = sum(d['sentiment'] for d in treemap_data) / len(treemap_data)
        total_posts = sum(d['post_count'] for d in treemap_data)
        total_market_cap = sum(d['market_cap'] for d in treemap_data)
    else:
        avg_sentiment = 0
        total_posts = 0
        total_market_cap = 0

    return jsonify({
        'success': True,
        'data': treemap_data,
        'summary': {
            'total_symbols': len(treemap_data),
            'avg_sentiment': round(avg_sentiment, 3),
            'total_posts': total_posts,
            'total_market_cap': format_market_cap(total_market_cap),
            'bullish_count': len([d for d in treemap_data if d['sentiment'] > 0.1]),
            'bearish_count': len([d for d in treemap_data if d['sentiment'] < -0.1]),
            'neutral_count': len([d for d in treemap_data if -0.1 <= d['sentiment'] <= 0.1])
        }
    })


@app.route('/api/presets')
def api_presets():
    """Return preset symbol groups."""
    presets = {
        'tech': ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'META', 'NVDA', 'TSLA', 'AMD', 'INTC', 'CRM'],
        'finance': ['JPM', 'BAC', 'WFC', 'GS', 'MS', 'C', 'BLK', 'SCHW', 'AXP', 'V'],
        'healthcare': ['JNJ', 'UNH', 'PFE', 'ABBV', 'MRK', 'LLY', 'TMO', 'ABT', 'DHR', 'BMY'],
        'meme': ['GME', 'AMC', 'BB', 'BBBY', 'PLTR', 'SOFI', 'WISH', 'CLOV', 'SPCE', 'TLRY'],
        'sp500_top10': ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'NVDA', 'META', 'TSLA', 'BRK-B', 'UNH', 'JNJ'],
        'etfs': ['SPY', 'QQQ', 'IWM', 'DIA', 'VTI', 'VOO', 'ARKK', 'XLF', 'XLK', 'XLE']
    }
    return jsonify(presets)


if __name__ == '__main__':
    # Validate environment on startup
    if reddit is None:
        logger.error("=" * 60)
        logger.error("Reddit API credentials not configured!")
        logger.error("The application requires valid Reddit API credentials.")
        logger.error("")
        logger.error("To set up Reddit API access:")
        logger.error("1. Go to https://www.reddit.com/prefs/apps")
        logger.error("2. Create a new application (script type)")
        logger.error("3. Set these environment variables in your .env file:")
        logger.error("   REDDIT_CLIENT_ID=<your_client_id>")
        logger.error("   REDDIT_CLIENT_SECRET=<your_client_secret>")
        logger.error("   REDDIT_USER_AGENT=RedditSentimentScraper/1.0")
        logger.error("=" * 60)
    else:
        logger.info("Reddit API configured successfully")

    app.run(debug=True, host='0.0.0.0', port=5000)
