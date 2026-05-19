import urllib.request
import json

url = 'https://serpapi.com/search?engine=google_maps&q=KFC&location=Dubai,UAE&api_key=d972824cb222333d2c9268177969132f6e8daa5a8755ff2f941797d06a27255f'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req, timeout=20) as resp:
        data = json.loads(resp.read().decode())
        print('Status:', resp.status)
        results = data.get('local_results', [])
        print('Results:', len(results))
        for r in results[:3]:
            title = r.get('title', '')
            addr = r.get('address', '')
            rating = r.get('rating', 0)
            print(f'  {title} - {addr} - Rating: {rating}')
except Exception as e:
    print('Error:', type(e).__name__, str(e))