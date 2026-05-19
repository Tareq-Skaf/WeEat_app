import urllib.request
import json

url = "https://serpapi.com/search?engine=google_maps&q=KFC&ll=@25.2048,55.2708,14z&api_key=d972824cb222333d2c9268177969132f6e8daa5a8755ff2f941797d06a27255f"
req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        data = json.loads(resp.read().decode())
        results = data.get("local_results", [])
        print(f"Status: {resp.status}")
        print(f"Results: {len(results)}")
        for r in results[:5]:
            print(f"  {r.get('title')} - {r.get('address')} - Rating: {r.get('rating')}")
except Exception as e:
    print(f"Error: {type(e).__name__}: {str(e)[:200]}")