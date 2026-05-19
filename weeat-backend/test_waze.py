import os
import http.client
import json

RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY", "")
if not RAPIDAPI_KEY:
    print("ERROR: Set RAPIDAPI_KEY environment variable.")
    exit(1)

conn = http.client.HTTPSConnection("waze.p.rapidapi.com")

headers = {
    'x-rapidapi-key': RAPIDAPI_KEY,
    'x-rapidapi-host': "waze.p.rapidapi.com",
    'Content-Type': "application/json"
}

# Dubai area coordinates
conn.request("GET", "/alerts-and-jams?bottom_left=25.0%2C55.0&top_right=25.4%2C55.5&radius_units=KM&max_alerts=10&max_jams=10", headers=headers)

res = conn.getresponse()
data = json.loads(res.read().decode("utf-8"))
print("Status:", res.status)
print("Keys:", list(data.keys()))
if 'alerts' in data:
    print(f"Alerts: {len(data['alerts'])}")
if 'jams' in data:
    print(f"Jams: {len(data['jams'])}")
print("Sample:", json.dumps(data, indent=2)[:500])
