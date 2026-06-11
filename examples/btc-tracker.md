Create a Python script fetch_bitcoin.py that fetches the current Bitcoin price
in USD from the free CoinGecko API and appends {timestamp, price, source} to
bitcoin_history.json (create it if missing, never overwrite history).
Verify: run it twice, exit code 0 both times, file contains 2+ valid entries.
Deliver: fetch_bitcoin.py, bitcoin_history.json, and a short usage note in
README-tracker.md.
