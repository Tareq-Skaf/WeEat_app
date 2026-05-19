import re
from datetime import datetime
from fastapi import APIRouter, HTTPException, Query
from typing import Optional

from .db import menus_col

router = APIRouter(prefix="/menus", tags=["menus"])


# ---------------------------------------------------------------------------
# Chain name extraction
# ---------------------------------------------------------------------------

KNOWN_CHAINS = {
    "KFC": [r"\bkfc\b"],
    "McDonalds": [r"\bmcdonald'?s?\b"],
    "Burger King": [r"\bburger king\b"],
    "Tim Hortons": [r"\btim hortons\b"],
    "Nandos": [r"\bnando'?s?\b"],
    "Pizza Hut": [r"\bpizza hut\b"],
    "Subway": [r"\bsubway\b"],
    "Krispy Kreme": [r"\bkrispy kreme\b"],
    "Starbucks": [r"\bstarbucks\b"],
    "Costa Coffee": [r"\bcosta coffee\b"],
    "Dunkin": [r"\bdunkin'?\b"],
    "Shake Shack": [r"\bshake shack\b"],
    "Chili's": [r"\bchili'?s?\b"],
    "TGI Fridays": [r"\btgi fridays?\b"],
    "IHOP": [r"\bihop\b"],
    "Denny's": [r"\bdenny'?s?\b"],
    "Hardee's": [r"\bhardee'?s?\b"],
    "Texas Chicken": [r"\btexas chicken\b"],
    "Popeyes": [r"\bpopeyes?\b"],
    "Wendy's": [r"\bwendy'?s?\b"],
    "Taco Bell": [r"\btaco bell\b"],
    "Dairy Queen": [r"\bdairy queen\b"],
    "Domino's": [r"\bdomino'?s?\b"],
    "Papa John's": [r"\bpapa john'?s?\b"],
    "Little Caesars": [r"\blittle caesars\b"],
    "Five Guys": [r"\bfive guys\b"],
    "Pret A Manger": [r"\bpret a manger\b"],
    "Caribou Coffee": [r"\bcaribou coffee\b"],
    "Paul": [r"\bpaul\b"],
    "Shakespeare and Co": [r"\bshakespeare\b"],
    "Le Pain Quotidien": [r"\ble pain quotidien\b"],
}


def extract_chain_name(restaurant_name: str) -> Optional[str]:
    """
    Extract canonical chain name from a raw restaurant name.
    Handles suffixes like ' - Dubai Mall', ' (Deira)', etc.
    Returns None if no known chain is detected.
    """
    if not restaurant_name:
        return None

    # 1. Strip parenthetical / bracket content
    cleaned = re.sub(r"\s*[\(\[].*?[\)\]]\s*", " ", restaurant_name)

    # 2. Strip common dash-separated location suffixes
    cleaned = re.sub(r"\s*[-–—]\s*.*$", "", cleaned)

    # 3. Strip common trailing city / mall / location words
    location_words = [
        "dubai", "abu dhabi", "sharjah", "ajman", "fujairah",
        "ras al khaimah", "umm al quwain", "al ain", "deira",
        "bur dubai", "jbr", "jlt", "downtown", "marina", "mall",
        "center", "centre", "street", "road", "avenue",
    ]
    lower_cleaned = cleaned.lower()
    for word in location_words:
        # Only strip if it's a trailing word
        lower_cleaned = re.sub(rf"\s+{re.escape(word)}\s*$", "", lower_cleaned)
        lower_cleaned = re.sub(rf"^{re.escape(word)}\s+", "", lower_cleaned)

    # 4. Match against known chains
    for canonical, patterns in KNOWN_CHAINS.items():
        for pat in patterns:
            if re.search(pat, lower_cleaned):
                return canonical

    return None


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _serialize_menu(doc: dict) -> dict:
    return {
        "chain_name": doc.get("chain_name", ""),
        "chain_name_lower": doc.get("chain_name_lower", ""),
        "categories": doc.get("categories", []),
        "updated_at": doc.get("updated_at", ""),
        "total_items": sum(len(cat.get("items", [])) for cat in doc.get("categories", [])),
    }


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.get("/chain/{chain_name}")
async def get_menu_by_chain(chain_name: str):
    """Get menu by canonical chain name (case-insensitive)."""
    doc = await menus_col.find_one({"chain_name_lower": chain_name.strip().lower()})
    if not doc:
        raise HTTPException(status_code=404, detail="Menu not found for this chain")
    return _serialize_menu(doc)


@router.get("/by-restaurant")
async def get_menu_by_restaurant_name(restaurant_name: str = Query(...)):
    """
    Pass a raw restaurant name (e.g. 'KFC - Dubai Mall') and the backend
    will extract the chain and return the menu.
    """
    chain = extract_chain_name(restaurant_name)
    if not chain:
        raise HTTPException(status_code=404, detail="No known chain detected for this restaurant")
    doc = await menus_col.find_one({"chain_name_lower": chain.lower()})
    if not doc:
        raise HTTPException(status_code=404, detail="Menu coming soon for this chain")
    return {**_serialize_menu(doc), "detected_chain": chain}


@router.post("")
async def upsert_chain_menu(payload: dict):
    """
    Upsert a chain menu. Expected payload:
    {
      "chain_name": "KFC",
      "categories": [
        {
          "name": "Buckets",
          "items": [
            {"name": "...", "description": "...", "price": 39.0, ...}
          ]
        }
      ]
    }
    """
    chain_name = payload.get("chain_name", "").strip()
    if not chain_name:
        raise HTTPException(status_code=400, detail="chain_name is required")

    categories = payload.get("categories", [])
    if not isinstance(categories, list):
        raise HTTPException(status_code=400, detail="categories must be a list")

    # Validate categories
    for cat in categories:
        if not cat.get("name"):
            raise HTTPException(status_code=400, detail="Each category must have a name")
        if not isinstance(cat.get("items", []), list):
            raise HTTPException(status_code=400, detail="category items must be a list")

    doc = {
        "chain_name": chain_name,
        "chain_name_lower": chain_name.lower(),
        "categories": categories,
        "updated_at": datetime.utcnow().isoformat(),
    }

    await menus_col.update_one(
        {"chain_name_lower": chain_name.lower()},
        {"$set": doc},
        upsert=True,
    )

    return {"ok": True, "chain_name": chain_name, "upserted": True}


@router.delete("/chain/{chain_name}")
async def delete_chain_menu(chain_name: str):
    result = await menus_col.delete_one({"chain_name_lower": chain_name.strip().lower()})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Menu not found")
    return {"ok": True, "deleted": True}


@router.get("")
async def list_chain_menus(limit: int = 50):
    """List all chain menus (useful for admin)."""
    cursor = menus_col.find({}).limit(limit)
    docs = await cursor.to_list(length=limit)
    return [_serialize_menu(d) for d in docs]


@router.get("/detect-chain")
async def detect_chain(restaurant_name: str = Query(...)):
    """Debug endpoint: see what chain a restaurant name maps to."""
    chain = extract_chain_name(restaurant_name)
    return {
        "input": restaurant_name,
        "detected_chain": chain,
        "has_menu": bool(
            await menus_col.find_one({"chain_name_lower": (chain or "").lower()})
        ) if chain else False,
    }
