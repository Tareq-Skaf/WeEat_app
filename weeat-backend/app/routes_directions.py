import os
import http.client
import json
from fastapi import APIRouter, HTTPException, Query

router = APIRouter(tags=["directions"])

RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY", "")
if not RAPIDAPI_KEY:
    print("WARNING: RAPIDAPI_KEY not set. Directions endpoint will fallback to OSRM only.")


def _decode_polyline(polyline_str: str) -> list:
    """Decode a Google Maps encoded polyline string into a list of {lat, lng} dicts."""
    if not polyline_str:
        return []

    index, lat, lng = 0, 0, 0
    coordinates = []

    while index < len(polyline_str):
        shift, result = 0, 0
        while True:
            byte = ord(polyline_str[index]) - 63
            index += 1
            result |= (byte & 0x1f) << shift
            shift += 5
            if not byte >= 0x20:
                break

        dlat = ~(result >> 1) if (result & 1) else (result >> 1)
        lat += dlat

        shift, result = 0, 0
        while True:
            byte = ord(polyline_str[index]) - 63
            index += 1
            result |= (byte & 0x1f) << shift
            shift += 5
            if not byte >= 0x20:
                break

        dlng = ~(result >> 1) if (result & 1) else (result >> 1)
        lng += dlng

        coordinates.append({"lat": lat / 100000.0, "lng": lng / 100000.0})

    return coordinates


@router.get("/directions")
async def get_directions(
    origin_lat: float = Query(...),
    origin_lng: float = Query(...),
    dest_lat: float = Query(...),
    dest_lng: float = Query(...),
    mode: str = Query(default="driving"),
):
    """Get directions with real travel time from Google Maps"""
    if not RAPIDAPI_KEY:
        return await _osrm_fallback(origin_lat, origin_lng, dest_lat, dest_lng, mode)

    try:
        conn = http.client.HTTPSConnection("google-map-places-new-v2.p.rapidapi.com")

        path = f"/maps/api/directions/json?origin={origin_lat},{origin_lng}&destination={dest_lat},{dest_lng}&mode={mode}&alternatives=true"

        headers = {
            'x-rapidapi-key': RAPIDAPI_KEY,
            'x-rapidapi-host': "google-map-places-new-v2.p.rapidapi.com",
        }

        conn.request("GET", path, headers=headers)
        res = conn.getresponse()
        data = json.loads(res.read().decode("utf-8"))
        conn.close()

        if res.status != 200:
            return await _osrm_fallback(origin_lat, origin_lng, dest_lat, dest_lng, mode)

        routes = data.get("routes", [])
        if not routes:
            return await _osrm_fallback(origin_lat, origin_lng, dest_lat, dest_lng, mode)

        route = routes[0]
        leg = route.get("legs", [{}])[0]
        encoded_polyline = route.get("overview_polyline", {}).get("points", "")

        return {
            "ok": True,
            "duration_seconds": leg.get("duration", {}).get("value", 0),
            "duration_text": leg.get("duration", {}).get("text", ""),
            "distance_meters": leg.get("distance", {}).get("value", 0),
            "distance_text": leg.get("distance", {}).get("text", ""),
            "start_address": leg.get("start_address", ""),
            "end_address": leg.get("end_address", ""),
            "polyline": _decode_polyline(encoded_polyline),
            "mode": mode,
        }
    except Exception as e:
        return await _osrm_fallback(origin_lat, origin_lng, dest_lat, dest_lng, mode)


async def _osrm_fallback(origin_lat, origin_lng, dest_lat, dest_lng, mode):
    """Fallback to OSRM with correct speed multipliers"""
    import urllib.request

    osrm_mode = "car" if mode == "driving" else "foot" if mode == "walking" else "bike"
    url = f"https://router.project-osrm.org/route/v1/{osrm_mode}/{origin_lng},{origin_lat};{dest_lng},{dest_lat}?overview=full&geometries=geojson"

    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
            route = data["routes"][0]
            duration = route["duration"]
            distance = route["distance"]
            geometry = route["geometry"]["coordinates"]

            # Apply realistic speed multipliers
            if mode == "walking":
                adjusted_duration = (distance / 1000) / 5 * 3600
            elif mode == "bicycling":
                adjusted_duration = (distance / 1000) / 15 * 3600
            else:
                adjusted_duration = duration

            # Format time
            if adjusted_duration < 60:
                time_text = f"{adjusted_duration:.0f} sec"
            elif adjusted_duration < 3600:
                time_text = f"{adjusted_duration/60:.0f} min"
            else:
                hours = int(adjusted_duration / 3600)
                mins = int((adjusted_duration % 3600) / 60)
                time_text = f"{hours}h {mins}min"

            # Format distance
            if distance < 1000:
                dist_text = f"{distance:.0f} m"
            else:
                dist_text = f"{distance/1000:.1f} km"

            points = []
            for coord in geometry:
                points.append({"lat": coord[1], "lng": coord[0]})

            return {
                "ok": True,
                "duration_seconds": int(adjusted_duration),
                "duration_text": time_text,
                "distance_meters": int(distance),
                "distance_text": dist_text,
                "polyline": points,
                "mode": mode,
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
