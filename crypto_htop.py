import requests
import time
import os
from rich.console import Console
from rich.table import Table
from rich.live import Live
from rich.panel import Panel
from rich.text import Text

def get_top_cryptos():
    url = "https://api.coingecko.com/api/v3/coins/markets"
    params = {
        "vs_currency": "usd",
        "order": "market_cap_desc",
        "per_page": 20,
        "page": 1,
        "sparkline": "true"
    }
    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        # Check that the response is a list
        if not isinstance(data, list):
            raise ValueError("Invalid API response")
            
        return data
    except requests.exceptions.RequestException as e:
        raise Exception(f"Connection error: {e}")
    except ValueError as e:
        raise Exception(f"Data error: {e}")
    except Exception as e:
        raise Exception(f"Unexpected error: {e}")

def create_sparkline(prices, width=20):
    """Creates a simple line chart with ASCII characters"""
    if not prices or len(prices) < 2:
        return "─" * width
    
    # Normalize prices for display
    min_price = min(prices)
    max_price = max(prices)
    if max_price == min_price:
        return "─" * width
    
    # Characters for the chart
    chars = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
    
    sparkline = ""
    for price in prices:
        if price is None:
            sparkline += "─"
        else:
            # Normalize between 0 and 7 for character indices
            normalized = (price - min_price) / (max_price - min_price)
            char_index = min(int(normalized * 7), 7)
            sparkline += chars[char_index]
    
    return sparkline

def create_hourly_sparkline(prices, width=20):
    """Creates a line chart for 1-hour evolution"""
    if not prices or len(prices) < 2:
        return "─" * width
    
    # Take the last 24 data points (for 1 hour with 2.5 min intervals)
    # Or the last 60 if available
    recent_prices = prices[-24:] if len(prices) >= 24 else prices
    
    # Normalize prices for display
    min_price = min(recent_prices)
    max_price = max(recent_prices)
    if max_price == min_price:
        return "─" * width
    
    # Characters for the chart (more variation for 1h)
    chars = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
    
    sparkline = ""
    for price in recent_prices:
        if price is None:
            sparkline += "─"
        else:
            # Normalize between 0 and 7 for character indices
            normalized = (price - min_price) / (max_price - min_price)
            char_index = min(int(normalized * 7), 7)
            sparkline += chars[char_index]
    
    return sparkline

def create_table(data):
    table = Table(title="Top 50 Cryptocurrencies - 24h & 1h Evolution - Refreshed every 30 seconds", show_lines=True)

    table.add_column("Rank", style="bold cyan")
    table.add_column("Name", style="bold")
    table.add_column("Symbol", style="magenta")
    table.add_column("Price (USD)", style="green")
    table.add_column("24h Change (%)", style="red")
    table.add_column("1h Evolution", style="yellow")
    table.add_column("24h Evolution", style="blue")

    for i, coin in enumerate(data, 1):
        try:
            # Check that coin is a dictionary
            if not isinstance(coin, dict):
                continue
                
            name = coin.get('name', 'N/A')
            symbol = coin.get('symbol', 'N/A').upper()
            current_price = coin.get('current_price', 0)
            price_change = coin.get('price_change_percentage_24h', None)
            sparkline_data = coin.get('sparkline_in_7d', {}).get('price', [])
            
            price = f"{current_price:.2f}" if current_price is not None else "N/A"
            change_str = f"{price_change:.2f}" if price_change is not None else "N/A"
            change_color = "green" if price_change is not None and price_change >= 0 else "red"
            
            # Create line charts
            sparkline_24h = create_sparkline(sparkline_data)
            sparkline_1h = create_hourly_sparkline(sparkline_data)
            
            table.add_row(
                str(i),
                name,
                symbol,
                price,
                f"[{change_color}]{change_str}[/{change_color}]",
                sparkline_1h,
                sparkline_24h
            )
        except Exception as e:
            # Ignore problematic entries
            continue

    return table

def main():
    console = Console()
    
    try:
        # Display data immediately on launch
        try:
            data = get_top_cryptos()
        except Exception as e:
            console.print(f"\n[red]Error: {e}[/red]")
            data = []
        
        with Live(create_table(data), refresh_per_second=1/30, screen=True) as live:
            while True:
                try:
                    time.sleep(30)
                    data = get_top_cryptos()
                    table = create_table(data)
                    live.update(table)
                except KeyboardInterrupt:
                    console.print("\n[yellow]Stopping program...[/yellow]")
                    break
                except Exception as e:
                    console.print(f"\n[red]Error: {e}[/red]")
                    time.sleep(30)
    except KeyboardInterrupt:
        console.print("\n[yellow]Stopping program...[/yellow]")

if __name__ == "__main__":
    main() 