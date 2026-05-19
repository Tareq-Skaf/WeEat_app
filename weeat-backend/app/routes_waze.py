import os
import http.client
import json
from fastapi import APIRouter, HTTPException, Query
from typing import Optional

router = APIRouter(tags=["waze"])

RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY", "")
if not RAPIDAPI_KEY:
    print("WARNING: RAPIDAPI_KEY not set. Waze endpoints will fail.")


def _waze_request(path: str) -> dict:
    conn = http.client.HTTPSConnection("waze.p.rapidapi.com")
    headers = {
        'x-rapidapi-key': RAPIDAPI_KEY,
        'x-rapidapi-host': "waze.p.rapidapi.com",
        'Content-Type': "application/json"
    }
    conn.request("GET", path, headers=headers)
    res = conn.getresponse()
    data = json.loads(res.read().decode("utf-8"))
    conn.close()
    return {"status": res.status, "data": data}


@router.get("/waze/traffic")
async def get_traffic(
    lat: float = Query(...),
    lng: float = Query(...),
    radius_km: float = Query(default=5),
):
    """Get traffic alerts and jams near a location"""
    try:
        # Calculate bounding box from center point and radius
        lat_offset = radius_km / 111.0
        lng_offset = radius_km / (111.0 * abs(lat / 90.0 + 0.001))
        
        bottom_left = f"{lat - lat_offset},{lng - lng_offset}"
        top_right = f"{lat + lat_offset},{lng + lng_offset}"
        
        path = f"/alerts-and-jams?bottom_left={bottom_left}&top_right={top_right}&radius_units=KM&max_alerts=20&max_jams=20"
        
        result = _waze_request(path)
        
        if result["status"] != 200:
            raise HTTPException(status_code=result["status"], detail="Waze API error")
        
        data = result["data"]
        alerts = data.get("data", {}).get("alerts", [])
        jams = data.get("data", {}).get("jams", [])
        
        # Process alerts
        processed_alerts = []
        for alert in alerts:
            processed_alerts.append({
                "id": alert.get("alert_id", ""),
                "type": alert.get("type", ""),
                "description": alert.get("description", ""),
                "lat": alert.get("location", {}).get("y", 0),
                "lng": alert.get("location", {}).get("x", 0),
                "street": alert.get("street", ""),
                "report_time": alert.get("report_time", ""),
            })
        
        # Process jams
        processed_jams = []
        for jam in jams:
            processed_jams.append({
                "id": jam.get("jam_id", ""),
                "level": jam.get("level", 0),
                "length": jam.get("length", 0),
                "delay": jam.get("delay", 0),
                "speed": jam.get("speed", 0),
                "street": jam.get("street", ""),
                "city": jam.get("city", ""),
            })
        
        return {
            "ok": True,
            "alerts": processed_alerts,
            "jams": processed_jams,
            "total_alerts": len(processed_alerts),
            "total_jams": len(processed_jams),
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))