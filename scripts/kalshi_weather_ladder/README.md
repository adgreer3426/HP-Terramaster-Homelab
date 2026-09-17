# Kalshi Weather Ladder Scanner

Scans Kalshi's daily high/low temperature "ladder" markets and flags the
top or bottom rung of each city's ladder when its ask price (YES or NO
side) hits a threshold — 99 cents by default, i.e. the market considers
that extreme outcome a near-lock.

## Setup

1. Generate an RSA key pair and upload the public key in the Kalshi
   dashboard (Settings -> API Keys) to get an API Key ID:

   ```
   openssl genrsa -out kalshi_private_key.pem 4096
   openssl rsa -in kalshi_private_key.pem -pubout -out kalshi_public_key.pem
   ```

2. Install dependencies:

   ```
   pip install -r requirements.txt
   ```

3. Set credentials (don't commit these):

   ```
   export KALSHI_API_KEY_ID="your-api-key-id"
   export KALSHI_PRIVATE_KEY_PATH="/secure/path/kalshi_private_key.pem"
   ```

## Usage

```
python3 kalshi_weather_ladder_scanner.py
python3 kalshi_weather_ladder_scanner.py --threshold 99 --csv results.csv
python3 kalshi_weather_ladder_scanner.py --series KXHIGHNY,KXLOWNY
python3 kalshi_weather_ladder_scanner.py --demo
```

Run it any time — via cron, or by hand — to check current ladders.

## If Kalshi changes ticker naming

The script auto-discovers weather series from Kalshi's `/series` endpoint
by matching ticker prefixes and category/title text. Kalshi has renamed
weather ticker prefixes before (e.g. legacy `HIGHNY` -> `KXHIGHNY`). If a
future rename makes auto-discovery come up empty, pass the exact tickers
manually with `--series`, found at https://kalshi.com/hub/weather.

Use `--dump-raw` to print a sample raw series/market JSON object to
stderr — handy if Kalshi changes field names (e.g. `floor_strike`) and
you need to adjust `strike_sort_key()` in the script.

## Security note

Never commit your private key or API key ID to this repo. Keep them in
environment variables or a local, gitignored file.
