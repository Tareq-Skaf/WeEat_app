"""
WeEat Backend - Unit & Integration Tests
Run: pytest test_weeat.py -v
"""
import pytest
import http.client
import json
import os
from dotenv import load_dotenv

load_dotenv()

BASE_URL = "http://localhost:8000"
FOURSQUARE_KEY = os.getenv("FOURSQUARE_API_KEY", "")


# ============================================
# UNIT TESTS
# ============================================

class TestHealthEndpoint:
    """Test the health check endpoint"""

    def test_health_returns_ok(self):
        """Health endpoint should return ok: true"""
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("GET", "/health")
        res = conn.getresponse()
        data = json.loads(res.read().decode())
        conn.close()

        assert res.status == 200
        assert data["ok"] is True


class TestFoursquareSearch:
    """Test Foursquare restaurant search"""

    def _search(self, q, near="Dubai", limit=5):
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("GET", f"/foursquare/search?q={q}&near={near}&limit={limit}")
        res = conn.getresponse()
        data = json.loads(res.read().decode())
        conn.close()
        return res.status, data

    def test_search_returns_results(self):
        """Searching 'KFC' should return results"""
        status, data = self._search("KFC")
        assert status == 200
        assert data["ok"] is True
        assert data["total"] > 0

    def test_search_returns_restaurants_list(self):
        """Response should contain restaurants list"""
        status, data = self._search("Pizza")
        assert "restaurants" in data
        assert isinstance(data["restaurants"], list)

    def test_restaurant_has_required_fields(self):
        """Each restaurant should have name, lat, lng"""
        status, data = self._search("McDonald's")
        if data["total"] > 0:
            r = data["restaurants"][0]
            assert "name" in r
            assert "lat" in r
            assert "lng" in r
            assert r["name"] != ""

    def test_restaurant_has_icon_url(self):
        """Each restaurant should have icon_url from Foursquare"""
        status, data = self._search("Starbucks")
        if data["total"] > 0:
            r = data["restaurants"][0]
            assert "icon_url" in r
            # Icon URL should contain 88px size
            if r["icon_url"]:
                assert "88" in r["icon_url"]

    def test_search_deduplicates_results(self):
        """Searching across UAE should not have duplicate fsq_ids"""
        status, data = self._search("KFC", limit=50)
        if data["total"] > 1:
            fsq_ids = [r["fsq_id"] for r in data["restaurants"]]
            assert len(fsq_ids) == len(set(fsq_ids))

    def test_search_returns_multiple_branches(self):
        """Searching 'KFC' should return multiple branches"""
        status, data = self._search("KFC", limit=50)
        assert data["total"] >= 3  # At least 3 KFC branches in UAE


class TestFoursquarePhotos:
    """Test Foursquare photo endpoint"""

    def _get_photos(self, fsq_id, limit=1):
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("GET", f"/foursquare/photos?fsq_id={fsq_id}&limit={limit}")
        res = conn.getresponse()
        data = json.loads(res.read().decode())
        conn.close()
        return res.status, data

    def test_photos_requires_fsq_id(self):
        """Should fail without fsq_id"""
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("GET", "/foursquare/photos")
        res = conn.getresponse()
        conn.close()
        assert res.status == 422  # Validation error

    def test_photos_returns_list(self):
        """Should return photos list"""
        # First get a valid fsq_id
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("GET", "/foursquare/search?q=KFC&near=Dubai&limit=1")
        res = conn.getresponse()
        search_data = json.loads(res.read().decode())
        conn.close()

        if search_data["total"] > 0:
            fsq_id = search_data["restaurants"][0]["fsq_id"]
            status, data = self._get_photos(fsq_id)
            assert status == 200
            assert data["ok"] is True
            assert "photos" in data


class TestAuthEndpoints:
    """Test authentication endpoints"""

    def test_register_requires_fields(self):
        """Register should fail without required fields"""
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("POST", "/auth/register",
                     body=json.dumps({}),
                     headers={"Content-Type": "application/json"})
        res = conn.getresponse()
        conn.close()
        assert res.status == 422

    def test_login_requires_email(self):
        """Login should fail without email"""
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("POST", "/auth/login",
                     body=json.dumps({"password": "test"}),
                     headers={"Content-Type": "application/json"})
        res = conn.getresponse()
        conn.close()
        assert res.status == 422

    def test_login_wrong_password(self):
        """Login with wrong password should fail"""
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("POST", "/auth/login",
                     body=json.dumps({"email": "tarek@test.com", "password": "wrong"}),
                     headers={"Content-Type": "application/json"})
        res = conn.getresponse()
        data = json.loads(res.read().decode())
        conn.close()
        assert res.status == 401

    def test_login_success(self):
        """Login with correct credentials should succeed"""
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("POST", "/auth/login",
                     body=json.dumps({"email": "tarek@test.com", "password": "password123"}),
                     headers={"Content-Type": "application/json"})
        res = conn.getresponse()
        data = json.loads(res.read().decode())
        conn.close()
        assert res.status == 200
        assert data["ok"] is True


class TestRestaurantEndpoints:
    """Test restaurant CRUD endpoints"""

    def test_list_restaurants(self):
        """GET /restaurants should return list"""
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("GET", "/restaurants?limit=5")
        res = conn.getresponse()
        data = json.loads(res.read().decode())
        conn.close()
        assert res.status == 200
        assert isinstance(data, list)

    def test_restaurant_search(self):
        """GET /restaurants/search should filter results"""
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("GET", "/restaurants/search?q=KFC")
        res = conn.getresponse()
        data = json.loads(res.read().decode())
        conn.close()
        assert res.status == 200


class TestDirectionsEndpoint:
    """Test directions endpoint"""

    def test_directions_returns_route(self):
        """Directions should return polyline"""
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("GET", "/directions?origin_lat=25.2&origin_lng=55.2&dest_lat=25.1&dest_lng=55.1&mode=driving")
        res = conn.getresponse()
        data = json.loads(res.read().decode())
        conn.close()
        assert res.status == 200
        assert data["ok"] is True
        assert "polyline" in data
        assert "duration_text" in data
        assert "distance_text" in data

    def test_directions_polyline_is_list(self):
        """Polyline should be a list of coordinates"""
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("GET", "/directions?origin_lat=25.2&origin_lng=55.2&dest_lat=25.1&dest_lng=55.1")
        res = conn.getresponse()
        data = json.loads(res.read().decode())
        conn.close()
        assert isinstance(data["polyline"], list)
        if len(data["polyline"]) > 0:
            point = data["polyline"][0]
            assert "lat" in point
            assert "lng" in point


# ============================================
# INTEGRATION TESTS
# ============================================

class TestSearchToDirections:
    """Integration: Search → Select → Get Directions"""

    def test_full_flow(self):
        """Search KFC → get first result → get directions"""
        # Step 1: Search
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("GET", "/foursquare/search?q=KFC&near=Dubai&limit=1")
        res = conn.getresponse()
        search = json.loads(res.read().decode())
        conn.close()

        assert search["total"] > 0
        restaurant = search["restaurants"][0]

        # Step 2: Get directions
        lat = restaurant["lat"]
        lng = restaurant["lng"]
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("GET", f"/directions?origin_lat=25.2&origin_lng=55.2&dest_lat={lat}&dest_lng={lng}")
        res = conn.getresponse()
        directions = json.loads(res.read().decode())
        conn.close()

        assert directions["ok"] is True
        assert len(directions["polyline"]) > 0


class TestSearchToPhotos:
    """Integration: Search → Get Photos"""

    def test_search_then_photos(self):
        """Search → get fsq_id → fetch photos"""
        # Step 1: Search
        conn = http.client.HTTPConnection("localhost", 8000)
        conn.request("GET", "/foursquare/search?q=Starbucks&near=Dubai&limit=1")
        res = conn.getresponse()
        search = json.loads(res.read().decode())
        conn.close()

        if search["total"] > 0:
            fsq_id = search["restaurants"][0]["fsq_id"]

            # Step 2: Get photos
            conn = http.client.HTTPConnection("localhost", 8000)
            conn.request("GET", f"/foursquare/photos?fsq_id={fsq_id}&limit=1")
            res = conn.getresponse()
            photos = json.loads(res.read().decode())
            conn.close()

            assert photos["ok"] is True
            assert "photos" in photos


# ============================================
# RUN TESTS
# ============================================
if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
