import os
import http.client
import json

RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY", "")
if not RAPIDAPI_KEY:
    print("ERROR: Set RAPIDAPI_KEY environment variable.")
    exit(1)

conn = http.client.HTTPSConnection("google-map-places-new-v2.p.rapidapi.com")

payload = json.dumps({
    "input": "KFC Dubai",
    "locationBias": {
        "circle": {
            "center": {"latitude": 25.2048, "longitude": 55.2708},
            "radius": 10000
        }
    },
    "includedPrimaryTypes": ["restaurant", "food"],
    "languageCode": "en",
    "regionCode": "AE"
})

headers = {
    'x-rapidapi-key': RAPIDAPI_KEY,
    'x-rapidapi-host': "google-map-places-new-v2.p.rapidapi.com",
    'Content-Type': "application/json",
    'X-Goog-FieldMask': "*"
}

try:
    conn.request("POST", "/v1/places:autocomplete", payload, headers)
    res = conn.getresponse()
    data = res.read()
    result = json.loads(data.decode("utf-8"))
    print("Status:", res.status)
    print("Keys:", list(result.keys()))
    if 'suggestions' in result:
        print("Suggestions:", len(result['suggestions']))
        for s in result['suggestions'][:3]:
            place = s.get('placePrediction', {})
            print(f"  {place.get('text', {}).get('text', '')} - {place.get('placeId', '')}")
    else:
        print("Response:", json.dumps(result, indent=2)[:500])
except Exception as e:
    print("Error:", type(e).__name__, str(e)[:200])
