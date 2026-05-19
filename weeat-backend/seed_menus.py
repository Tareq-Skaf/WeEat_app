import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from datetime import datetime

async def seed_menus():
    client = AsyncIOMotorClient('mongodb+srv://weeat_userr:123455@cluster01.rsszzqs.mongodb.net/?appName=Cluster01')
    db = client['weeat']
    menus_col = db["menus"]
    
    await menus_col.delete_many({})
    print("Cleared existing menus")
    
    restaurants = await db.restaurants.find({}).to_list(100)
    
    menus = {
        "KFC": [
            {"name": "Original Recipe Chicken", "description": "11 herbs and spices, crispy fried chicken", "price": 35, "category": "Chicken", "image": "https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=300"},
            {"name": "Zinger Burger", "description": "Spicy chicken fillet burger with lettuce and mayo", "price": 28, "category": "Burgers", "image": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300"},
            {"name": "Twister Wrap", "description": "Chicken strips with lettuce and sauce in a tortilla", "price": 25, "category": "Wraps", "image": "https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=300"},
            {"name": "Popcorn Chicken", "description": "Bite-sized crispy chicken pieces", "price": 22, "category": "Snacks", "image": "https://images.unsplash.com/photo-1562967914-608f82629710?w=300"},
            {"name": "Coleslaw", "description": "Creamy coleslaw side", "price": 10, "category": "Sides", "image": "https://images.unsplash.com/photo-1625944525533-47371c3b2e0a?w=300"},
            {"name": "Fries", "description": "Golden crispy fries", "price": 12, "category": "Sides", "image": "https://images.unsplash.com/photo-1573080496219-bb080dd4f00f?w=300"},
            {"name": "Pepsi", "description": "Refreshing cola drink", "price": 8, "category": "Drinks", "image": "https://images.unsplash.com/photo-1629203851122-37266df6b0f0?w=300"},
            {"name": "Chocolate Cake", "description": "Rich chocolate cake slice", "price": 15, "category": "Desserts", "image": "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=300"},
        ],
        "McDonald's": [
            {"name": "Big Mac", "description": "Two beef patties, special sauce, lettuce, cheese", "price": 32, "category": "Burgers", "image": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300"},
            {"name": "Quarter Pounder", "description": "Quarter pound beef patty with cheese", "price": 30, "category": "Burgers", "image": "https://images.unsplash.com/photo-1550547660-d9450f82934e?w=300"},
            {"name": "McChicken", "description": "Crispy chicken patty with lettuce and mayo", "price": 25, "category": "Burgers", "image": "https://images.unsplash.com/photo-1606755456206-b25206cde27e?w=300"},
            {"name": "French Fries", "description": "World-famous golden fries", "price": 12, "category": "Sides", "image": "https://images.unsplash.com/photo-1573080496219-bb080dd4f00f?w=300"},
            {"name": "Chicken McNuggets", "description": "6-piece crispy chicken nuggets", "price": 20, "category": "Snacks", "image": "https://images.unsplash.com/photo-1562967914-608f82629710?w=300"},
            {"name": "McFlurry", "description": "Oreo McFlurry ice cream", "price": 18, "category": "Desserts", "image": "https://images.unsplash.com/photo-1572490122747-3968b75cc6fd?w=300"},
            {"name": "Coca-Cola", "description": "Ice-cold Coca-Cola", "price": 8, "category": "Drinks", "image": "https://images.unsplash.com/photo-1629203851122-37266df6b0f0?w=300"},
            {"name": "Apple Pie", "description": "Hot apple pie", "price": 12, "category": "Desserts", "image": "https://images.unsplash.com/photo-1535920527002-b35e96722eb9?w=300"},
        ],
        "Burger King": [
            {"name": "Whopper", "description": "Flame-grilled beef patty with tomatoes, lettuce, mayo", "price": 35, "category": "Burgers", "image": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300"},
            {"name": "Chicken Royale", "description": "Crispy chicken fillet burger", "price": 30, "category": "Burgers", "image": "https://images.unsplash.com/photo-1606755456206-b25206cde27e?w=300"},
            {"name": "Onion Rings", "description": "Crispy battered onion rings", "price": 15, "category": "Sides", "image": "https://images.unsplash.com/photo-1633504581786-316c8052b123?w=300"},
            {"name": "Fries", "description": "Golden fries", "price": 12, "category": "Sides", "image": "https://images.unsplash.com/photo-1573080496219-bb080dd4f00f?w=300"},
            {"name": "Milkshake", "description": "Chocolate milkshake", "price": 18, "category": "Drinks", "image": "https://images.unsplash.com/photo-1572490122747-3968b75cc6fd?w=300"},
            {"name": "Sundae", "description": "Caramel sundae", "price": 14, "category": "Desserts", "image": "https://images.unsplash.com/photo-1563805042-7684c519e15f?w=300"},
        ],
        "Subway": [
            {"name": "Italian BMT", "description": "Salami, pepperoni, ham with veggies", "price": 28, "category": "Subs", "image": "https://images.unsplash.com/photo-1553909489-cd47e0907980?w=300"},
            {"name": "Chicken Teriyaki", "description": "Teriyaki chicken with veggies", "price": 30, "category": "Subs", "image": "https://images.unsplash.com/photo-1550547660-d9450f82934e?w=300"},
            {"name": "Turkey Breast", "description": "Sliced turkey with veggies", "price": 26, "category": "Subs", "image": "https://images.unsplash.com/photo-1509722747573-0cc8ba0c0e5c?w=300"},
            {"name": "Veggie Delite", "description": "Fresh vegetables with your choice of sauce", "price": 22, "category": "Subs", "image": "https://images.unsplash.com/photo-1540914124281-342587941389?w=300"},
            {"name": "Cookie", "description": "Chocolate chip cookie", "price": 8, "category": "Sides", "image": "https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=300"},
            {"name": "Chips", "description": "Lays chips", "price": 6, "category": "Sides", "image": "https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=300"},
        ],
        "Papa John's": [
            {"name": "Pepperoni Pizza", "description": "Classic pepperoni with mozzarella", "price": 42, "category": "Pizza", "image": "https://images.unsplash.com/photo-1628840042765-356cda075f68?w=300"},
            {"name": "Margherita Pizza", "description": "Tomato, mozzarella, basil", "price": 35, "category": "Pizza", "image": "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=300"},
            {"name": "Chicken BBQ Pizza", "description": "BBQ chicken with onions", "price": 48, "category": "Pizza", "image": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=300"},
            {"name": "Garlic Bread", "description": "Freshly baked garlic bread", "price": 15, "category": "Sides", "image": "https://images.unsplash.com/photo-1619535860434-cf8f499baf44?w=300"},
            {"name": "Chicken Wings", "description": "Spicy chicken wings (6 pcs)", "price": 28, "category": "Sides", "image": "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=300"},
            {"name": "Pepsi", "description": "Refreshing cola", "price": 8, "category": "Drinks", "image": "https://images.unsplash.com/photo-1629203851122-37266df6b0f0?w=300"},
        ],
        "The Cheesecake Factory": [
            {"name": "Avocado Egg Rolls", "description": "Crispy egg rolls with avocado", "price": 45, "category": "Appetizers", "image": "https://images.unsplash.com/photo-1536964549204-cce9eab227bd?w=300"},
            {"name": "Chicken Madeira", "description": "Chicken with mushrooms and asparagus", "price": 75, "category": "Mains", "image": "https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=300"},
            {"name": "Pasta Carbonara", "description": "Creamy pasta with bacon", "price": 65, "category": "Mains", "image": "https://images.unsplash.com/photo-1612874742237-6526221588e3?w=300"},
            {"name": "Original Cheesecake", "description": "Famous original cheesecake", "price": 42, "category": "Desserts", "image": "https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=300"},
            {"name": "Oreo Cheesecake", "description": "Oreo cookies and cream cheesecake", "price": 48, "category": "Desserts", "image": "https://images.unsplash.com/photo-1567171466295-4afa63d45416?w=300"},
            {"name": "Fresh Lemonade", "description": "Freshly squeezed lemonade", "price": 22, "category": "Drinks", "image": "https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=300"},
        ],
        "Al Mallah": [
            {"name": "Falafel Plate", "description": "Crispy falafel with tahini and pickles", "price": 18, "category": "Starters", "image": "https://images.unsplash.com/photo-1593001874117-c99c800e3eb7?w=300"},
            {"name": "Shawarma Plate", "description": "Chicken shawarma with garlic sauce", "price": 28, "category": "Mains", "image": "https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=300"},
            {"name": "Hummus", "description": "Creamy chickpea dip", "price": 15, "category": "Starters", "image": "https://images.unsplash.com/photo-1577805947697-89e18249d767?w=300"},
            {"name": "Fattoush Salad", "description": "Fresh salad with crispy bread", "price": 18, "category": "Salads", "image": "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=300"},
            {"name": "Manakish", "description": "Lebanese flatbread with zaatar", "price": 12, "category": "Bread", "image": "https://images.unsplash.com/photo-1593001874117-c99c800e3eb7?w=300"},
            {"name": "Fresh Juice", "description": "Orange or lemon juice", "price": 12, "category": "Drinks", "image": "https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=300"},
        ],
        "Starbucks": [
            {"name": "Caffe Latte", "description": "Espresso with steamed milk", "price": 22, "category": "Coffee", "image": "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=300"},
            {"name": "Cappuccino", "description": "Espresso with foam", "price": 20, "category": "Coffee", "image": "https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=300"},
            {"name": "Caramel Macchiato", "description": "Vanilla, caramel, espresso", "price": 26, "category": "Coffee", "image": "https://images.unsplash.com/photo-1485808191679-5f86510681a2?w=300"},
            {"name": "Frappuccino", "description": "Blended coffee with ice", "price": 28, "category": "Cold Drinks", "image": "https://images.unsplash.com/photo-1572490122747-3968b75cc6fd?w=300"},
            {"name": "Chocolate Cake", "description": "Rich chocolate cake", "price": 22, "category": "Food", "image": "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=300"},
            {"name": "Croissant", "description": "Buttery flaky croissant", "price": 14, "category": "Food", "image": "https://images.unsplash.com/photo-1555507036-ab1f4038024a?w=300"},
        ],
        "Nando's": [
            {"name": "Peri-Peri Chicken", "description": "Flame-grilled chicken with peri-peri sauce", "price": 55, "category": "Chicken", "image": "https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=300"},
            {"name": "Chicken Butterfly", "description": "Butterflied chicken breast", "price": 48, "category": "Chicken", "image": "https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=300"},
            {"name": "Peri-Peri Fries", "description": "Fries with peri-peri seasoning", "price": 18, "category": "Sides", "image": "https://images.unsplash.com/photo-1573080496219-bb080dd4f00f?w=300"},
            {"name": "Coleslaw", "description": "Creamy coleslaw", "price": 12, "category": "Sides", "image": "https://images.unsplash.com/photo-1625944525533-47371c3b2e0a?w=300"},
            {"name": "Corn on the Cob", "description": "Grilled corn with butter", "price": 15, "category": "Sides", "image": "https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=300"},
            {"name": "Perinaise", "description": "Peri-peri mayo dip", "price": 6, "category": "Sides", "image": "https://images.unsplash.com/photo-1472476443507-c7a5948772fc?w=300"},
        ],
        "Pizza Hut": [
            {"name": "Supreme Pizza", "description": "Pepperoni, sausage, peppers, onions", "price": 48, "category": "Pizza", "image": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=300"},
            {"name": "Cheese Pizza", "description": "Extra cheese pizza", "price": 35, "category": "Pizza", "image": "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=300"},
            {"name": "Meat Lovers", "description": "Pepperoni, sausage, ham, bacon", "price": 55, "category": "Pizza", "image": "https://images.unsplash.com/photo-1628840042765-356cda075f68?w=300"},
            {"name": "Garlic Bread", "description": "Cheesy garlic bread", "price": 18, "category": "Sides", "image": "https://images.unsplash.com/photo-1619535860434-cf8f499baf44?w=300"},
            {"name": "Pasta", "description": "Chicken Alfredo pasta", "price": 38, "category": "Pasta", "image": "https://images.unsplash.com/photo-1612874742237-6526221588e3?w=300"},
            {"name": "Pepsi", "description": "Ice-cold Pepsi", "price": 8, "category": "Drinks", "image": "https://images.unsplash.com/photo-1629203851122-37266df6b0f0?w=300"},
        ],
        "Ravi Restaurant": [
            {"name": "Butter Chicken", "description": "Creamy tomato chicken curry", "price": 32, "category": "Curry", "image": "https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=300"},
            {"name": "Biryani", "description": "Fragrant rice with chicken", "price": 28, "category": "Rice", "image": "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300"},
            {"name": "Naan Bread", "description": "Fresh baked naan", "price": 5, "category": "Bread", "image": "https://images.unsplash.com/photo-1593001874117-c99c800e3eb7?w=300"},
            {"name": "Dal", "description": "Lentil curry", "price": 18, "category": "Curry", "image": "https://images.unsplash.com/photo-1546833998-877b37c2e5c6?w=300"},
            {"name": "Tandoori Chicken", "description": "Clay oven roasted chicken", "price": 35, "category": "Grill", "image": "https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=300"},
            {"name": "Mango Lassi", "description": "Sweet mango yogurt drink", "price": 12, "category": "Drinks", "image": "https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=300"},
        ],
    }
    
    added = 0
    for restaurant in restaurants:
        name = restaurant.get("name", "")
        if name in menus:
            menu_items = menus[name]
            for item in menu_items:
                item["restaurant_id"] = str(restaurant["_id"])
                item["restaurant_name"] = name
                item["created_at"] = datetime.utcnow().isoformat()
            
            await menus_col.insert_many(menu_items)
            print(f"  Added {len(menu_items)} menu items for {name}")
            added += len(menu_items)
    
    print(f"\nTotal: {added} menu items added with images")

asyncio.run(seed_menus())