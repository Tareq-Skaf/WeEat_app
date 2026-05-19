#!/usr/bin/env python3
"""
Seed script for WeEat chain menus.
Run from the weeat-backend directory:
    .venv\\Scripts\\python.exe seed_chain_menus.py
"""
import asyncio
import os
import sys

# ensure app package is importable
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.db import menus_col

MENUS = [
    {
        "chain_name": "KFC",
        "chain_name_lower": "kfc",
        "categories": [
            {
                "name": "Buckets & Boxes",
                "items": [
                    {"name": "Zinger Stacker Meal", "description": "Crispy chicken fillet stacked with lettuce, cheese, and spicy mayo", "price": 39.0, "image_url": "", "is_vegetarian": False, "is_spicy": True, "calories": 850},
                    {"name": "Twister Box", "description": "Twister wrap, fries, drink, and coleslaw", "price": 32.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 720},
                    {"name": "Mighty Zinger", "description": "Double crispy fillet with cheese, jalapeños, and supercharged sauce", "price": 45.0, "image_url": "", "is_vegetarian": False, "is_spicy": True, "calories": 1100},
                    {"name": "Dinner Bucket (8 pcs)", "description": "8 pieces of Original Recipe chicken, 4 buns, and 2 large sides", "price": 89.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 2800},
                ]
            },
            {
                "name": "Burgers",
                "items": [
                    {"name": "Zinger Burger", "description": "Classic crispy Zinger fillet with lettuce and mayo", "price": 22.0, "image_url": "", "is_vegetarian": False, "is_spicy": True, "calories": 520},
                    {"name": "Kentucky Burger", "description": "Original Recipe fillet with cheese and BBQ sauce", "price": 24.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 580},
                ]
            },
            {
                "name": "Sides",
                "items": [
                    {"name": "Fries", "description": "Golden crispy fries seasoned with KFC signature spice", "price": 8.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 280},
                    {"name": "Coleslaw", "description": "Creamy cabbage and carrot salad", "price": 7.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 160},
                    {"name": "Mashed Potato", "description": "Smooth mashed potato with gravy", "price": 7.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 140},
                    {"name": "Corn on the Cob", "description": "Sweet corn cob with butter", "price": 6.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 90},
                ]
            },
            {
                "name": "Beverages & Desserts",
                "items": [
                    {"name": "Pepsi", "description": "Refreshing Pepsi", "price": 5.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 150},
                    {"name": "7UP", "description": "Crisp lemon-lime soda", "price": 5.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 140},
                    {"name": "Chocolate Cake", "description": "Rich molten chocolate cake", "price": 12.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 340},
                ]
            },
        ]
    },
    {
        "chain_name": "McDonalds",
        "chain_name_lower": "mcdonalds",
        "categories": [
            {
                "name": "Burgers",
                "items": [
                    {"name": "Big Mac", "description": "Two all-beef patties, special sauce, lettuce, cheese, pickles, onions on a sesame seed bun", "price": 22.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 550},
                    {"name": "Quarter Pounder", "description": "Quarter pound beef patty with cheese, onions, pickles, ketchup, and mustard", "price": 24.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 520},
                    {"name": "McChicken", "description": "Crispy chicken patty with lettuce and mayo", "price": 19.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 480},
                    {"name": "Filet-O-Fish", "description": "Battered fish fillet with tartar sauce and cheese", "price": 18.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 380},
                    {"name": "Double Cheeseburger", "description": "Two beef patties with two slices of cheese", "price": 20.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 450},
                ]
            },
            {
                "name": "Meals",
                "items": [
                    {"name": "Big Mac Meal", "description": "Big Mac, medium fries, and medium drink", "price": 32.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 1080},
                    {"name": "McChicken Meal", "description": "McChicken, medium fries, and medium drink", "price": 29.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 1010},
                    {"name": "Happy Meal", "description": "Kids burger, small fries, drink, and toy", "price": 24.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 530},
                ]
            },
            {
                "name": "Sides & Salads",
                "items": [
                    {"name": "Fries", "description": "World-famous golden fries", "price": 9.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 320},
                    {"name": "Apple Slices", "description": "Fresh apple slices", "price": 8.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 15},
                    {"name": "Garden Salad", "description": "Mixed greens with cherry tomatoes and balsamic dressing", "price": 12.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 80},
                ]
            },
            {
                "name": "McCafé & Desserts",
                "items": [
                    {"name": "McCafé Latte", "description": "Rich espresso with steamed milk", "price": 14.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 140},
                    {"name": "McFlurry Oreo", "description": "Vanilla soft serve blended with Oreo cookie pieces", "price": 12.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 280},
                    {"name": "Apple Pie", "description": "Warm apple pie with cinnamon", "price": 8.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 250},
                    {"name": "Caramel Sundae", "description": "Vanilla soft serve with caramel sauce", "price": 9.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 210},
                ]
            },
        ]
    },
    {
        "chain_name": "Burger King",
        "chain_name_lower": "burger king",
        "categories": [
            {
                "name": "Flame-Grilled Burgers",
                "items": [
                    {"name": "Whopper", "description": "Flame-grilled beef patty with tomatoes, lettuce, mayo, ketchup, pickles, and onions", "price": 26.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 660},
                    {"name": "Whopper with Cheese", "description": "Classic Whopper with melted American cheese", "price": 28.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 730},
                    {"name": "Bacon King", "description": "Two flame-grilled beef patties with crispy bacon and cheese", "price": 32.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 1050},
                    {"name": "Chicken Royale", "description": "Crispy chicken fillet with lettuce and mayo on a sesame bun", "price": 22.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 580},
                    {"name": "Big King", "description": "Two beef patties, special sauce, lettuce, cheese, pickles, onions", "price": 24.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 530},
                ]
            },
            {
                "name": "Meals",
                "items": [
                    {"name": "Whopper Meal", "description": "Whopper, fries, and drink", "price": 38.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 1180},
                    {"name": "Chicken Royale Meal", "description": "Chicken Royale, fries, and drink", "price": 34.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 980},
                ]
            },
            {
                "name": "Sides",
                "items": [
                    {"name": "Onion Rings", "description": "Crispy battered onion rings", "price": 10.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 320},
                    {"name": "Fries", "description": "Thick-cut golden fries", "price": 9.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 300},
                    {"name": "Mozzarella Sticks", "description": "Breaded mozzarella cheese sticks with marinara dip", "price": 14.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 280},
                    {"name": "Cheesy Bites", "description": "Bite-sized cheese-filled pockets", "price": 12.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 240},
                ]
            },
            {
                "name": "Beverages & Desserts",
                "items": [
                    {"name": "Coca-Cola", "description": "Classic Coca-Cola", "price": 5.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 140},
                    {"name": "Vanilla Shake", "description": "Creamy vanilla hand-spun shake", "price": 15.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 380},
                    {"name": "Chocolate Sundae", "description": "Soft serve with rich chocolate sauce", "price": 10.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 210},
                ]
            },
        ]
    },
    {
        "chain_name": "Tim Hortons",
        "chain_name_lower": "tim hortons",
        "categories": [
            {
                "name": "Coffee & Hot Beverages",
                "items": [
                    {"name": "Double Double", "description": "Coffee with two creams and two sugars", "price": 14.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 120},
                    {"name": "French Vanilla", "description": "Sweet and creamy French vanilla cappuccino", "price": 16.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 180},
                    {"name": "Premium Blend Dark Roast", "description": "Rich dark roast coffee", "price": 13.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 5},
                    {"name": "Hot Chocolate", "description": "Creamy hot chocolate topped with whipped cream", "price": 15.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 220},
                ]
            },
            {
                "name": "Cold Beverages",
                "items": [
                    {"name": "Iced Capp", "description": "Frozen coffee beverage blended with cream", "price": 18.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 280},
                    {"name": "Iced Coffee", "description": "Freshly brewed coffee over ice", "price": 15.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 80},
                    {"name": "Real Fruit Smoothie", "description": "Blended strawberry and banana smoothie", "price": 19.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 160},
                ]
            },
            {
                "name": "Donuts & Timbits",
                "items": [
                    {"name": "Honey Dip", "description": "Classic yeast donut glazed with honey", "price": 6.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 210},
                    {"name": "Boston Cream", "description": "Filled with custard and topped with chocolate", "price": 7.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 230},
                    {"name": "Maple Dip", "description": "Classic donut dipped in maple frosting", "price": 6.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 220},
                    {"name": "10 Pack Timbits", "description": "Assorted bite-sized donut holes", "price": 12.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 380},
                ]
            },
            {
                "name": "Sandwiches & Paninis",
                "items": [
                    {"name": "Turkey Bacon Club", "description": "Roasted turkey breast with bacon, lettuce, and tomato", "price": 28.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 450},
                    {"name": "Grilled Cheese Panini", "description": "Melted cheddar and mozzarella on grilled bread", "price": 22.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 520},
                    {"name": "Egg & Cheese Muffin", "description": "Fluffy egg and melted cheese on an English muffin", "price": 18.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 320},
                ]
            },
            {
                "name": "Bakery",
                "items": [
                    {"name": "Blueberry Muffin", "description": "Baked with real Canadian blueberries", "price": 12.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 340},
                    {"name": "Butter Croissant", "description": "Flaky, buttery French-style croissant", "price": 10.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 280},
                ]
            },
        ]
    },
    {
        "chain_name": "Nandos",
        "chain_name_lower": "nandos",
        "categories": [
            {
                "name": "Peri-Peri Chicken",
                "items": [
                    {"name": "1/4 Chicken", "description": "Quarter chicken flame-grilled with your choice of peri-peri baste", "price": 34.0, "image_url": "", "is_vegetarian": False, "is_spicy": True, "calories": 380},
                    {"name": "1/2 Chicken", "description": "Half chicken flame-grilled with your choice of peri-peri baste", "price": 56.0, "image_url": "", "is_vegetarian": False, "is_spicy": True, "calories": 720},
                    {"name": "Chicken Burger", "description": "Grilled chicken breast with lettuce, tomato, and peri mayo", "price": 32.0, "image_url": "", "is_vegetarian": False, "is_spicy": True, "calories": 480},
                    {"name": "Chicken Wrap", "description": "Grilled chicken strips, lettuce, and spicy mayo in a warm wrap", "price": 30.0, "image_url": "", "is_vegetarian": False, "is_spicy": True, "calories": 420},
                    {"name": "Chicken Skewers (2 pcs)", "description": "Tender chicken thigh skewers basted in peri-peri", "price": 28.0, "image_url": "", "is_vegetarian": False, "is_spicy": True, "calories": 340},
                ]
            },
            {
                "name": "Sharing Platters",
                "items": [
                    {"name": "Full Platter", "description": "Whole chicken, 2 large sides, and 4 garlic breads", "price": 145.0, "image_url": "", "is_vegetarian": False, "is_spicy": True, "calories": 2400},
                    {"name": "Wings Platter (10 pcs)", "description": "10 chicken wings with 2 dips and 1 large side", "price": 68.0, "image_url": "", "is_vegetarian": False, "is_spicy": True, "calories": 980},
                ]
            },
            {
                "name": "Sides",
                "items": [
                    {"name": "Peri-Peri Fries", "description": "Crispy fries dusted with peri-peri salt", "price": 14.0, "image_url": "", "is_vegetarian": True, "is_spicy": True, "calories": 320},
                    {"name": "Spicy Rice", "description": "Fluffy rice with turmeric and mild spices", "price": 12.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 260},
                    {"name": "Coleslaw", "description": "Fresh and crunchy coleslaw", "price": 10.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 150},
                    {"name": "Garlic Bread", "description": "Toasted bread with garlic butter", "price": 12.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 220},
                    {"name": "Mediterranean Salad", "description": "Mixed greens, feta, olives, and vinaigrette", "price": 18.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 180},
                ]
            },
            {
                "name": "Desserts & Drinks",
                "items": [
                    {"name": "Carrot Cake", "description": "Spiced carrot cake with cream cheese frosting", "price": 18.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 380},
                    {"name": "Gelato (2 scoops)", "description": "Creamy Italian-style gelato", "price": 15.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 200},
                    {"name": "Coca-Cola", "description": "Classic Coke", "price": 5.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 140},
                    {"name": "San Pellegrino", "description": "Sparkling natural mineral water", "price": 12.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 0},
                ]
            },
        ]
    },
    {
        "chain_name": "Pizza Hut",
        "chain_name_lower": "pizza hut",
        "categories": [
            {
                "name": "Pizzas",
                "items": [
                    {"name": "Margherita", "description": "Classic tomato sauce and mozzarella cheese", "price": 28.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 720},
                    {"name": "Pepperoni Feast", "description": "Generous layer of pepperoni on mozzarella", "price": 35.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 980},
                    {"name": "Super Supreme", "description": "Pepperoni, beef, mushrooms, onions, olives, and peppers", "price": 42.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 1120},
                    {"name": "Veggie Supreme", "description": "Mushrooms, peppers, onions, tomatoes, olives, and corn", "price": 38.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 860},
                    {"name": "BBQ Chicken", "description": "Grilled chicken, BBQ sauce, onions, and peppers", "price": 40.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 1080},
                    {"name": "Cheese Lovers", "description": "Mozzarella, cheddar, parmesan, and cream cheese", "price": 36.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 1050},
                ]
            },
            {
                "name": "Sides",
                "items": [
                    {"name": "Breadsticks (6 pcs)", "description": "Warm garlic and herb breadsticks", "price": 14.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 240},
                    {"name": "Chicken Wings (8 pcs)", "description": "Crispy wings tossed in spicy buffalo sauce", "price": 24.0, "image_url": "", "is_vegetarian": False, "is_spicy": True, "calories": 480},
                    {"name": "Cheesy Garlic Bread", "description": "Thick-cut garlic bread loaded with mozzarella", "price": 16.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 320},
                    {"name": "Potato Wedges", "description": "Seasoned potato wedges with sour cream dip", "price": 14.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 280},
                ]
            },
            {
                "name": "Pasta",
                "items": [
                    {"name": "Chicken Alfredo", "description": "Creamy alfredo pasta with grilled chicken", "price": 32.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 620},
                    {"name": "Bolognese", "description": "Classic meat sauce over spaghetti", "price": 30.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 580},
                    {"name": "Creamy Mushroom Pasta", "description": "Fettuccine in a rich mushroom cream sauce", "price": 28.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 540},
                ]
            },
            {
                "name": "Desserts & Drinks",
                "items": [
                    {"name": "Hershey's Chocolate Chip Cookie", "description": "Warm giant cookie loaded with Hershey's chips", "price": 22.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 420},
                    {"name": "Cinnamon Sticks", "description": "Sweet cinnamon breadsticks with icing dip", "price": 16.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 320},
                    {"name": "Pepsi", "description": "Classic Pepsi", "price": 5.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 150},
                    {"name": "Mountain Dew", "description": "Citrus-flavored soda", "price": 5.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 170},
                ]
            },
        ]
    },
    {
        "chain_name": "Subway",
        "chain_name_lower": "subway",
        "categories": [
            {
                "name": "Subway Series",
                "items": [
                    {"name": "Italian BMT", "description": "Genoa salami, pepperoni, Black Forest ham, and cheese", "price": 28.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 450},
                    {"name": "Turkey Breast", "description": "Lean turkey breast with fresh veggies", "price": 26.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 280},
                    {"name": "Chicken Teriyaki", "description": "Sweet teriyaki glazed chicken strips", "price": 27.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 380},
                    {"name": "Tuna", "description": "Flaked tuna mixed with light mayo", "price": 26.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 480},
                    {"name": "Veggie Delite", "description": "Fresh veggies and cheese on your choice of bread", "price": 22.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 230},
                ]
            },
            {
                "name": "Wraps",
                "items": [
                    {"name": "Chicken & Bacon Ranch Wrap", "description": "Crispy chicken, bacon, and ranch in a tortilla wrap", "price": 28.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 520},
                    {"name": "Veggie Wrap", "description": "Fresh veggies and hummus in a spinach wrap", "price": 20.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 290},
                    {"name": "Steak & Cheese Wrap", "description": "Steak strips with melted cheese and grilled onions", "price": 29.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 480},
                ]
            },
            {
                "name": "Salads",
                "items": [
                    {"name": "Chicken Breast Salad", "description": "Grilled chicken on a bed of mixed greens", "price": 26.0, "image_url": "", "is_vegetarian": False, "is_spicy": False, "calories": 220},
                    {"name": "Veggie Salad", "description": "Fresh lettuce, tomatoes, peppers, olives, and cucumbers", "price": 20.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 120},
                ]
            },
            {
                "name": "Sides & Drinks",
                "items": [
                    {"name": "Chocolate Chip Cookie", "description": "Freshly baked cookie with chocolate chips", "price": 5.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 210},
                    {"name": "Lays Chips", "description": "Classic salted potato chips", "price": 4.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 160},
                    {"name": "Coca-Cola", "description": "Classic Coke", "price": 5.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 140},
                    {"name": "Dasani Water", "description": "Refreshing bottled water", "price": 4.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 0},
                ]
            },
        ]
    },
    {
        "chain_name": "Krispy Kreme",
        "chain_name_lower": "krispy kreme",
        "categories": [
            {
                "name": "Signature Doughnuts",
                "items": [
                    {"name": "Original Glazed", "description": "The iconic light and fluffy glazed doughnut", "price": 6.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 190},
                    {"name": "Chocolate Iced Glazed", "description": "Original glazed with rich chocolate icing", "price": 7.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 240},
                    {"name": "Strawberry Sprinkles", "description": "Strawberry icing with rainbow sprinkles", "price": 8.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 260},
                    {"name": "Caramel Iced", "description": "Original glazed topped with caramel icing", "price": 7.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 250},
                    {"name": "Glazed Raspberry", "description": "Filled with real raspberry jelly", "price": 8.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 270},
                ]
            },
            {
                "name": "Filled Doughnuts",
                "items": [
                    {"name": "Custard Filled", "description": "Soft doughnut filled with vanilla custard", "price": 8.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 290},
                    {"name": "Lemon Filled", "description": "Tangy lemon curd filled doughnut", "price": 8.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 280},
                    {"name": "Chocolate Kreme Filled", "description": "Rich chocolate cream filled doughnut", "price": 8.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 300},
                ]
            },
            {
                "name": "Boxes",
                "items": [
                    {"name": "Original Glazed Dozen", "description": "12 signature original glazed doughnuts", "price": 50.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 2280},
                    {"name": "Assorted Dozen", "description": "12 assorted doughnuts of your choice", "price": 65.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 2800},
                    {"name": "Mini Doughnuts (16 pcs)", "description": "Bite-sized original glazed minis", "price": 35.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 800},
                ]
            },
            {
                "name": "Coffee & Chillers",
                "items": [
                    {"name": "Brewed Coffee", "description": "Smooth Arabica coffee", "price": 12.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 5},
                    {"name": "Latte", "description": "Espresso with steamed milk", "price": 16.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 120},
                    {"name": "Original Chiller", "description": "Blended iced coffee drink", "price": 18.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 240},
                    {"name": "Caramel Chiller", "description": "Iced blended coffee with caramel", "price": 19.0, "image_url": "", "is_vegetarian": True, "is_spicy": False, "calories": 280},
                ]
            },
        ]
    },
]


async def main():
    print("Seeding chain menus into MongoDB...")
    count_before = await menus_col.count_documents({})
    print(f"Menus before: {count_before}")

    # Upsert each menu
    for menu in MENUS:
        await menus_col.update_one(
            {"chain_name_lower": menu["chain_name_lower"]},
            {"$set": menu},
            upsert=True,
        )
        total_items = sum(len(cat.get("items", [])) for cat in menu["categories"])
        print(f"  -> {menu['chain_name']}: {len(menu['categories'])} categories, {total_items} items")

    count_after = await menus_col.count_documents({})
    print(f"\nMenus after: {count_after}")
    print("Done!")


if __name__ == "__main__":
    asyncio.run(main())
