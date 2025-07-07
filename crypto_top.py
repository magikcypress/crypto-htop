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
        
        # Vérifier que la réponse est une liste
        if not isinstance(data, list):
            raise ValueError("Réponse API invalide")
            
        return data
    except requests.exceptions.RequestException as e:
        raise Exception(f"Erreur de connexion: {e}")
    except ValueError as e:
        raise Exception(f"Erreur de données: {e}")
    except Exception as e:
        raise Exception(f"Erreur inattendue: {e}")

def create_sparkline(prices, width=20):
    """Crée un graphique en ligne simple avec des caractères ASCII"""
    if not prices or len(prices) < 2:
        return "─" * width
    
    # Normaliser les prix pour l'affichage
    min_price = min(prices)
    max_price = max(prices)
    if max_price == min_price:
        return "─" * width
    
    # Caractères pour le graphique
    chars = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
    
    sparkline = ""
    for price in prices:
        if price is None:
            sparkline += "─"
        else:
            # Normaliser entre 0 et 7 pour les indices de caractères
            normalized = (price - min_price) / (max_price - min_price)
            char_index = min(int(normalized * 7), 7)
            sparkline += chars[char_index]
    
    return sparkline

def create_hourly_sparkline(prices, width=20):
    """Crée un graphique en ligne pour l'évolution sur 1 heure"""
    if not prices or len(prices) < 2:
        return "─" * width
    
    # Prendre les dernières 24 données (pour 1 heure avec 2.5 min d'intervalle)
    # Ou les 60 dernières si disponibles
    recent_prices = prices[-24:] if len(prices) >= 24 else prices
    
    # Normaliser les prix pour l'affichage
    min_price = min(recent_prices)
    max_price = max(recent_prices)
    if max_price == min_price:
        return "─" * width
    
    # Caractères pour le graphique (plus de variation pour 1h)
    chars = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
    
    sparkline = ""
    for price in recent_prices:
        if price is None:
            sparkline += "─"
        else:
            # Normaliser entre 0 et 7 pour les indices de caractères
            normalized = (price - min_price) / (max_price - min_price)
            char_index = min(int(normalized * 7), 7)
            sparkline += chars[char_index]
    
    return sparkline

def create_table(data):
    table = Table(title="Top 50 Cryptomonnaies - Évolution 24h & 1h - Rafraîchi toutes les 30 secondes", show_lines=True)

    table.add_column("Rang", style="bold cyan")
    table.add_column("Nom", style="bold")
    table.add_column("Symbole", style="magenta")
    table.add_column("Prix (USD)", style="green")
    table.add_column("Variation 24h (%)", style="red")
    table.add_column("Évolution 1h", style="yellow")
    table.add_column("Évolution 24h", style="blue")

    for i, coin in enumerate(data, 1):
        try:
            # Vérifier que coin est un dictionnaire
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
            
            # Créer les graphiques en ligne
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
            # Ignorer les entrées problématiques
            continue

    return table

def main():
    console = Console()
    
    try:
        # Afficher les données immédiatement au lancement
        try:
            data = get_top_cryptos()
        except Exception as e:
            console.print(f"\n[red]Erreur: {e}[/red]")
            data = []
        
        with Live(create_table(data), refresh_per_second=1/30, screen=True) as live:
            while True:
                try:
                    time.sleep(30)
                    data = get_top_cryptos()
                    table = create_table(data)
                    live.update(table)
                except KeyboardInterrupt:
                    console.print("\n[yellow]Arrêt du programme...[/yellow]")
                    break
                except Exception as e:
                    console.print(f"\n[red]Erreur: {e}[/red]")
                    time.sleep(30)
    except KeyboardInterrupt:
        console.print("\n[yellow]Arrêt du programme...[/yellow]")

if __name__ == "__main__":
    main() 