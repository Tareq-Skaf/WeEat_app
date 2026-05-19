import asyncio
from motor.motor_asyncio import AsyncIOMotorClient

async def update_images():
    client = AsyncIOMotorClient('mongodb+srv://weeat_userr:123455@cluster01.rsszzqs.mongodb.net/?appName=Cluster01')
    db = client['weeat']
    
    # Real restaurant logos/images
    restaurant_images = {
        "KFC": "https://upload.wikimedia.org/wikipedia/en/thumb/b/bf/KFC_logo.svg/1200px-KFC_logo.svg.png",
        "McDonald's": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/McDonald%27s_Golden_Arches.svg/1200px-McDonald%27s_Golden_Arches.svg.png",
        "Burger King": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Burger_King_logo_%281999%29.svg/1200px-Burger_King_logo_%281999%29.svg.png",
        "Subway": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Subway_2016_logo.svg/1200px-Subway_2016_logo.svg.png",
        "Papa John's": "https://upload.wikimedia.org/wikipedia/en/thumb/d/d2/Papa_John%27s_logo.svg/1200px-Papa_John%27s_logo.svg.png",
        "Starbucks": "https://upload.wikimedia.org/wikipedia/en/thumb/d/d3/Starbucks_Corporation_Logo_2011.svg/1200px-Starbucks_Corporation_Logo_2011.svg.png",
        "Pizza Hut": "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/Pizza_Hut.svg/1200px-Pizza_Hut.svg.png",
        "Domino's Pizza": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Domino%27s_pizza_logo.svg/1200px-Domino%27s_pizza_logo.svg.png",
        "Nando's": "https://upload.wikimedia.org/wikipedia/en/thumb/7/7b/Nando%27s_logo.svg/1200px-Nando%27s_logo.svg.png",
        "The Cheesecake Factory": "https://upload.wikimedia.org/wikipedia/en/thumb/4/44/The_Cheesecake_Factory_logo.svg/1200px-The_Cheesecake_Factory_logo.svg.png",
        "TGI Friday's": "https://upload.wikimedia.org/wikipedia/en/thumb/3/3c/TGI_Fridays_logo.svg/1200px-TGI_Fridays_logo.svg.png",
        "Chili's": "https://upload.wikimedia.org/wikipedia/en/thumb/5/5f/Chili%27s_Grill_%26_Bar_logo.svg/1200px-Chili%27s_Grill_%26_Bar_logo.svg.png",
        "Tim Hortons": "https://upload.wikimedia.org/wikipedia/en/thumb/b/b5/Tim_Hortons_Logo.svg/1200px-Tim_Hortons_Logo.svg.png",
        "Baskin-Robbins": "https://upload.wikimedia.org/wikipedia/en/thumb/5/57/Baskin-Robbins_logo.svg/1200px-Baskin-Robbins_logo.svg.png",
        "Wagamama": "https://upload.wikimedia.org/wikipedia/en/thumb/2/2e/Wagamama_logo.svg/1200px-Wagamama_logo.svg.png",
        "Yo! Sushi": "https://upload.wikimedia.org/wikipedia/en/thumb/3/3e/Yo_Sushi_logo.svg/1200px-Yo_Sushi_logo.svg.png",
        "P.F. Chang's": "https://upload.wikimedia.org/wikipedia/en/thumb/2/2e/P.F._Chang%27s_logo.svg/1200px-P.F._Chang%27s_logo.svg.png",
        "Al Mallah": "https://images.unsplash.com/photo-1541518763669-27fef04b14ea?w=500",
        "Zaroob": "https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=500",
        "Operation: Falafel": "https://images.unsplash.com/photo-1593001874117-c99c800e3eb7?w=500",
        "Pierchic": "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=500",
        "Zuma": "https://images.unsplash.com/photo-1579027989536-b7b1f875659b?w=500",
        "Ravi Restaurant": "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=500",
        "Karachi Darbar": "https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=500",
    }
    
    # Real food images for menu items
    menu_item_images = {
        # KFC
        "Original Recipe Chicken": "https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=300",
        "Zinger Burger": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300",
        "Twister Wrap": "https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=300",
        "Popcorn Chicken": "https://images.unsplash.com/photo-1562967914-608f82629710?w=300",
        "Coleslaw": "https://images.unsplash.com/photo-1625944525533-47371c3b2e0a?w=300",
        "Fries": "https://images.unsplash.com/photo-1573080496219-bb080dd4f00f?w=300",
        "Pepsi": "https://images.unsplash.com/photo-1629203851122-37266df6b0f0?w=300",
        "Chocolate Cake": "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=300",
        # McDonald's
        "Big Mac": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300",
        "Quarter Pounder": "https://images.unsplash.com/photo-1550547660-d9450f82934e?w=300",
        "McChicken": "https://images.unsplash.com/photo-1606755456206-b25206cde27e?w=300",
        "French Fries": "https://images.unsplash.com/photo-1573080496219-bb080dd4f00f?w=300",
        "Chicken McNuggets": "https://images.unsplash.com/photo-1562967914-608f82629710?w=300",
        "McFlurry": "https://images.unsplash.com/photo-1572490122747-3968b75cc6fd?w=300",
        "Coca-Cola": "https://images.unsplash.com/photo-1629203851122-37266df6b0f0?w=300",
        "Apple Pie": "https://images.unsplash.com/photo-1535920527002-b35e96722eb9?w=300",
        # Burger King
        "Whopper": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300",
        "Chicken Royale": "https://images.unsplash.com/photo-1606755456206-b25206cde27e?w=300",
        "Onion Rings": "https://images.unsplash.com/photo-1633504581786-316c8052b123?w=300",
        "Milkshake": "https://images.unsplash.com/photo-1572490122747-3968b75cc6fd?w=300",
        "Sundae": "https://images.unsplash.com/photo-1563805042-7684c519e15f?w=300",
        # Subway
        "Italian BMT": "https://images.unsplash.com/photo-1553909489-cd47e0907980?w=300",
        "Chicken Teriyaki": "https://images.unsplash.com/photo-1550547660-d9450f82934e?w=300",
        "Turkey Breast": "https://images.unsplash.com/photo-1509722747573-0cc8ba0c0e5c?w=300",
        "Veggie Delite": "https://images.unsplash.com/photo-1540914124281-342587941389?w=300",
        "Cookie": "https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=300",
        # Papa John's
        "Pepperoni Pizza": "https://images.unsplash.com/photo-1628840042765-356cda075f68?w=300",
        "Margherita Pizza": "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=300",
        "Chicken BBQ Pizza": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=300",
        "Garlic Bread": "https://images.unsplash.com/photo-1619535860434-cf8f499baf44?w=300",
        "Chicken Wings": "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=300",
        # Starbucks
        "Caffe Latte": "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=300",
        "Cappuccino": "https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=300",
        "Caramel Macchiato": "https://images.unsplash.com/photo-1485808191679-5f86510681a2?w=300",
        "Frappuccino": "https://images.unsplash.com/photo-1572490122747-3968b75cc6fd?w=300",
        "Chocolate Cake": "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=300",
        "Croissant": "https://images.unsplash.com/photo-1555507036-ab1f4038024a?w=300",
        # Nando's
        "Peri-Peri Chicken": "https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=300",
        "Chicken Butterfly": "https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=300",
        "Peri-Peri Fries": "https://images.unsplash.com/photo-1573080496219-bb080dd4f00f?w=300",
        "Corn on the Cob": "https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=300",
        # Pizza Hut
        "Supreme Pizza": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=300",
        "Cheese Pizza": "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=300",
        "Meat Lovers": "https://images.unsplash.com/photo-1628840042765-356cda075f68?w=300",
        # Ravi Restaurant
        "Butter Chicken": "https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=300",
        "Biryani": "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300",
        "Naan Bread": "https://images.unsplash.com/photo-1593001874117-c99c800e3eb7?w=300",
        "Dal": "https://images.unsplash.com/photo-1546833998-877b37c2e5c6?w=300",
        "Tandoori Chicken": "https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=300",
        "Mango Lassi": "https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=300",
        # The Cheesecake Factory
        "Avocado Egg Rolls": "https://images.unsplash.com/photo-1536964549204-cce9eab227bd?w=300",
        "Chicken Madeira": "https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=300",
        "Pasta Carbonara": "https://images.unsplash.com/photo-1612874742237-6526221588e3?w=300",
        "Original Cheesecake": "https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=300",
        "Oreo Cheesecake": "https://images.unsplash.com/photo-1567171466295-4afa63d45416?w=300",
        "Fresh Lemonade": "https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=300",
        # Al Mallah
        "Falafel Plate": "https://images.unsplash.com/photo-1593001874117-c99c800e3eb7?w=300",
        "Shawarma Plate": "https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=300",
        "Hummus": "https://images.unsplash.com/photo-1577805947697-89e18249d767?w=300",
        "Fattoush Salad": "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=300",
        "Manakish": "https://images.unsplash.com/photo-1593001874117-c99c800e3eb7?w=300",
    }
    
    # Update restaurant images
    restaurants = await db.restaurants.find({}).to_list(100)
    for r in restaurants:
        name = r.get("name", "")
        if name in restaurant_images:
            await db.restaurants.update_one(
                {"_id": r["_id"]},
                {"$set": {"imageUrl": restaurant_images[name]}}
            )
            print(f"  Updated {name} logo")
    
    # Update menu item images
    menus = await db.menus.find({}).to_list(500)
    for m in menus:
        name = m.get("name", "")
        if name in menu_item_images:
            await db.menus.update_one(
                {"_id": m["_id"]},
                {"$set": {"image": menu_item_images[name]}}
            )
    
    print(f"\nUpdated {len(restaurant_images)} restaurant images")
    print(f"Updated {len(menu_item_images)} menu item images")

asyncio.run(update_images())