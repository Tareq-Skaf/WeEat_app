import os
import http.client
import json
from fastapi import APIRouter, HTTPException

router = APIRouter(tags=["ip"])

RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY", "")
if not RAPIDAPI_KEY:
    print("WARNING: RAPIDAPI_KEY not set. IP location endpoint will fail.")


@router.get("/user/location")
async def get_user_location():
    """Get user's location based on their IP address"""
    try:
        conn = http.client.HTTPSConnection("user-ip-data-rest-api.p.rapidapi.com")
        headers = {
            'x-rapidapi-key': RAPIDAPI_KEY,
            'x-rapidapi-host': "user-ip-data-rest-api.p.rapidapi.com",
            'Content-Type': "application/json"
        }
        conn.request("GET", "/check", headers=headers)
        res = conn.getresponse()
        data = json.loads(res.read().decode("utf-8"))
        conn.close()

        if res.status != 200:
            raise HTTPException(status_code=res.status, detail="IP API error")

        return {
            "ok": True,
            "ip": data.get("ip", ""),
            "city": data.get("city", ""),
            "region": data.get("region", ""),
            "country": data.get("country", ""),
            "lat": data.get("latitude", 0),
            "lng": data.get("longitude", 0),
            "timezone": data.get("timezone", ""),
            "isp": data.get("isp", ""),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))