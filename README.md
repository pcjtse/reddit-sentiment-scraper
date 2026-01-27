# Reddit Stock Sentiment Scraper

A powerful Python-based tool that analyzes sentiment trends and generates insights from Reddit discussions about specific stocks. This tool helps investors and analysts understand market sentiment by analyzing posts from popular stock-related subreddits.

## Features

- **Reddit Data Collection**: Scrapes live posts from multiple stock-related subreddits (wallstreetbets, stocks, investing)
- **Time-Based Analysis**: Focuses on posts from the last 7 days for current market sentiment
- **Sentiment Analysis**: Uses NLTK's VADER sentiment analyzer to evaluate post sentiment
- **Two Interfaces**:
  - **Web UI**: Interactive treemap heatmap visualization with Flask
  - **CLI Tool**: Command-line interface with detailed charts and analysis
- **Visualization**:
  - Interactive treemap heatmap (size = market cap, color = sentiment)
  - 7-day sentiment trend graph
  - Word cloud visualization
  - Daily post volume analysis
  - Subreddit distribution pie chart
  - Comment sentiment analysis by subreddit
  - Time of day distribution analysis
- **Smart Text Processing**:
  - Removes stock symbols and short words from word clouds
  - Combines post titles and content for comprehensive analysis
- **Top Posts Analysis**: Displays highest scoring posts with their sentiment scores

## Technical Details

The program uses several key technologies:
- **PRAW**: Python Reddit API Wrapper for Reddit data collection
- **NLTK**: Natural Language Toolkit for sentiment analysis
- **Flask**: Web framework for the interactive UI
- **yfinance**: Real-time stock data (market cap, sector, etc.)
- **Plotly**: Interactive treemap visualization
- **Pandas**: Data manipulation and analysis
- **Matplotlib**: Data visualization
- **WordCloud**: Text visualization
- **python-dotenv**: Environment variable management
- **Seaborn**: Advanced statistical visualizations

## Prerequisites

**Reddit API credentials are required.** This application fetches live data from Reddit and will not work without valid API credentials.

## Setup

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Get Reddit API Credentials (Required)

1. Go to https://www.reddit.com/prefs/apps
2. Scroll down and click **"create another app..."**
3. Fill in the form:
   - **Name**: `RedditSentimentScraper` (or any name you prefer)
   - **App type**: Select **"script"**
   - **Description**: `A script to analyze Reddit sentiment for stocks`
   - **About URL**: Leave blank
   - **Redirect URI**: `http://localhost:8080`
4. Click **"create app"**
5. Note down your credentials:
   - **Client ID**: The string under your app name (e.g., `aBcDeFgHiJkLmN`)
   - **Client Secret**: The string labeled "secret"

### 3. Configure Environment Variables

Create or edit the `.env` file in the project root:

```bash
REDDIT_CLIENT_ID=your_client_id_here
REDDIT_CLIENT_SECRET=your_client_secret_here
REDDIT_USER_AGENT=RedditSentimentScraper/1.0
```

Replace `your_client_id_here` and `your_client_secret_here` with your actual credentials.

## Usage

### Web UI (Recommended)

Start the Flask web server:

```bash
python app.py
```

Open your browser to http://localhost:5000

The web UI allows you to:
- Enter multiple stock symbols (comma-separated)
- Use preset groups (Tech Giants, Finance, Healthcare, Meme Stocks, etc.)
- View an interactive treemap where:
  - **Size** represents market capitalization
  - **Color** represents sentiment (green = bullish, red = bearish)
- See detailed statistics and a sortable data table

### Command-Line Interface

Run the CLI script:

```bash
python reddit_sentiment_scraper.py
```

Enter the stock symbol when prompted (e.g., AAPL, GOOGL, MSFT).

The script will:
1. Scrape posts from the last 7 days from stock-related subreddits
2. Perform sentiment analysis on the posts
3. Generate a sentiment trend graph
4. Create a word cloud from the posts
5. Display all visualizations

## Output

The program generates seven main analyses:

1. **Sentiment Trend Graph**: Shows the average sentiment score over the 7-day period
   - Positive values indicate bullish sentiment
   - Negative values indicate bearish sentiment
   - Values closer to zero indicate neutral sentiment

2. **Word Cloud**: Displays the most frequently used terms in the discussions
   - Larger words indicate more frequent usage
   - Stock symbols and short words are automatically filtered out

3. **Post Volume Analysis**: Bar chart showing the number of posts per day
   - Helps identify days with high discussion activity
   - Useful for tracking discussion momentum

4. **Subreddit Distribution**: Pie chart showing post distribution across subreddits
   - Helps understand which communities are most active
   - Shows relative importance of different subreddits

5. **Top Posts Analysis**: Displays the 5 highest-scoring posts
   - Shows post title, score, and sentiment
   - Helps identify most impactful discussions

6. **Comment Sentiment Analysis**: Box plot showing sentiment distribution of comments by subreddit
   - Compares comment sentiment across different subreddits
   - Helps identify which communities are more bullish/bearish

7. **Time Distribution Analysis**: Bar chart showing post activity by hour
   - Helps identify peak discussion times
   - Useful for understanding when the community is most active

## Troubleshooting

### "Reddit API credentials not configured" error

Make sure your `.env` file exists in the project root and contains valid credentials:

```bash
REDDIT_CLIENT_ID=your_actual_client_id
REDDIT_CLIENT_SECRET=your_actual_client_secret
REDDIT_USER_AGENT=RedditSentimentScraper/1.0
```

### "No posts found" for a symbol

This can happen when:
- The stock isn't being actively discussed on Reddit
- The symbol requires different search terms (e.g., some stocks are discussed by company name rather than ticker)
- Reddit API rate limiting is in effect

### API Rate Limiting

Reddit has rate limits on API requests. If you're analyzing many symbols, you may need to wait between requests. The application handles this gracefully but analysis may be slower.

## Limitations

- Reddit API rate limits may affect data collection
- Sentiment analysis accuracy depends on the quality and context of the posts
- Results may be skewed by meme stocks or highly volatile discussions
- Limited to publicly available Reddit data
- VADER sentiment analysis may not capture financial-specific language nuances

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see below for details:

```
MIT License

Copyright (c) 2024 RedditSentimentScraper

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Disclaimer

This tool is for educational and research purposes only. The sentiment analysis and insights provided should not be considered financial advice. Always conduct your own research and consult with financial professionals before making investment decisions. 