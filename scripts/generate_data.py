"""
generate_data.py
----------------
Creates the SIMULATED Zepto-style sales dataset used in this project
(written with AI assistance, because real Zepto sales data is not public).

What it builds (Jan-Jun 2025):
  - 12 categories, 106 real-brand grocery products with MRP and cost price
  - 22 dark stores across 6 cities
  - 2,000 customers, ~9,700 orders, ~34,400 order lines

Realistic patterns deliberately built in (and later discovered with SQL):
  - Month-on-month order growth (month_growth)
  - Weekend orders ~25% higher (wkend)
  - Morning and evening ordering peaks (hour_w), with slower delivery at peaks
  - Summer boost for ice creams and cold drinks in Apr-Jun (summer_boost)
  - Category-specific discounts and margins (categories list)
  - A few very loyal customers (Pareto distribution of customer weights)
  - Free delivery for orders of Rs 199 or more

Deliberate data-quality problems (fixed in sql/05_cleaning.sql):
  - Inconsistent city spellings, duplicate customers, missing brands,
    duplicate order lines, zero/negative quantities, missing values

Output: CSV files + one SQL setup script (CREATE TABLE + INSERT).
random.seed(42) makes the output identical every time it is run.
"""
import random, csv, os
from datetime import datetime, timedelta, date

random.seed(42)
OUT = "output"
os.makedirs(OUT, exist_ok=True)

# ---------------- categories ----------------
categories = [
    # id, name, avg discount %, margin % (on selling price), demand weight
    (1, "Fruits & Vegetables", 12, 28, 18),
    (2, "Dairy, Bread & Eggs", 4, 14, 22),
    (3, "Snacks & Munchies", 15, 30, 14),
    (4, "Cold Drinks & Juices", 10, 26, 10),
    (5, "Ice Creams & Frozen", 8, 27, 6),
    (6, "Atta, Rice & Dal", 9, 12, 8),
    (7, "Masala, Oil & More", 11, 16, 6),
    (8, "Breakfast & Instant Food", 13, 24, 7),
    (9, "Personal Care", 20, 35, 5),
    (10, "Home & Cleaning", 18, 32, 4),
    (11, "Baby Care", 10, 22, 2),
    (12, "Tea, Coffee & Health Drinks", 12, 20, 4),
]

# ---------------- products ----------------
P = {
 1: [("Banana Robusta 1 kg","Fresho",60,1000),("Tomato Hybrid 500 g","Fresho",30,500),("Onion 1 kg","Fresho",45,1000),
     ("Potato 1 kg","Fresho",40,1000),("Apple Shimla 4 pcs","Fresho",160,600),("Coriander Leaves 100 g","Fresho",15,100),
     ("Green Chilli 100 g","Fresho",12,100),("Carrot Ooty 500 g","Fresho",40,500),("Pomegranate 2 pcs","Fresho",140,500),
     ("Watermelon Kiran 1 pc","Fresho",90,2000),("Lemon 4 pcs","Fresho",25,200),("Cucumber 500 g","Fresho",28,500),
     ("Mango Alphonso 6 pcs","Fresho",599,1200),("Ginger 100 g","Fresho",20,100)],
 2: [("Amul Taaza Toned Milk 500 ml","Amul",28,500),("Amul Gold Full Cream Milk 1 L","Amul",68,1000),
     ("Nandini Toned Milk 500 ml","Nandini",24,500),("Britannia Brown Bread 400 g","Britannia",55,400),
     ("Harvest Gold White Bread 400 g","Harvest Gold",45,400),("Farm Fresh Eggs 6 pcs","Eggoz",60,360),
     ("Eggoz Protein Eggs 12 pcs","Eggoz",150,720),("Amul Butter 100 g","Amul",58,100),("Amul Masti Dahi 400 g","Amul",35,400),
     ("Milky Mist Paneer 200 g","Milky Mist",95,200),("Amul Cheese Slices 200 g","Amul",145,200),("Mother Dairy Curd 400 g","Mother Dairy",40,400)],
 3: [("Lay's Classic Salted 52 g","Lay's",20,52),("Kurkure Masala Munch 90 g","Kurkure",20,90),("Haldiram's Bhujia 400 g","Haldiram's",110,400),
     ("Bingo Mad Angles 66 g","Bingo",20,66),("Doritos Nacho Cheese 82 g","Doritos",50,82),("Britannia Good Day 200 g","Britannia",40,200),
     ("Parle-G 800 g","Parle",90,800),("Oreo Chocolate 120 g","Cadbury",35,120),("Dairy Milk Silk 60 g","Cadbury",90,60),
     ("KitKat 4 Finger 37 g","Nestle",30,37),("Pringles Sour Cream 107 g","Pringles",115,107),("Too Yumm Multigrain Chips 54 g","Too Yumm",20,54)],
 4: [("Coca-Cola 750 ml","Coca-Cola",40,750),("Thums Up 750 ml","Coca-Cola",40,750),("Sprite 750 ml","Coca-Cola",40,750),
     ("Real Fruit Juice Mixed 1 L","Dabur",125,1000),("Paper Boat Aamras 250 ml","Paper Boat",35,250),("Red Bull 250 ml","Red Bull",125,250),
     ("Bisleri Water 1 L","Bisleri",20,1000),("Tropicana Orange 1 L","Tropicana",130,1000),("Sting Energy 250 ml","PepsiCo",20,250),
     ("Raw Pressery Coconut Water 200 ml","Raw Pressery",60,200)],
 5: [("Amul Vanilla Ice Cream 1 L","Amul",180,1000),("Kwality Wall's Cornetto","Kwality Wall's",45,120),("Magnum Almond 80 ml","Kwality Wall's",90,80),
     ("Baskin Robbins Mississippi Mud 500 ml","Baskin Robbins",299,500),("McCain French Fries 420 g","McCain",130,420),
     ("Safal Frozen Green Peas 500 g","Safal",95,500),("ID Malabar Parota 5 pcs","iD Fresh",75,400),("Amul Kool Kesar Kulfi","Amul",30,60)],
 6: [("Aashirvaad Atta 5 kg","Aashirvaad",285,5000),("India Gate Basmati Rice 1 kg","India Gate",150,1000),("Tata Sampann Toor Dal 1 kg","Tata Sampann",185,1000),
     ("Fortune Sona Masoori Rice 5 kg","Fortune",395,5000),("Tata Sampann Moong Dal 500 g","Tata Sampann",95,500),("Pillsbury Chakki Atta 5 kg","Pillsbury",275,5000),
     ("Rajdhani Besan 500 g","Rajdhani",70,500)],
 7: [("Fortune Sunflower Oil 1 L","Fortune",165,1000),("Saffola Gold Oil 1 L","Saffola",210,1000),("Tata Salt 1 kg","Tata",28,1000),
     ("Everest Turmeric Powder 100 g","Everest",38,100),("MDH Garam Masala 100 g","MDH",92,100),("Catch Red Chilli Powder 100 g","Catch",45,100),
     ("Madhur Sugar 1 kg","Madhur",55,1000),("Patanjali Cow Ghee 500 ml","Patanjali",340,500)],
 8: [("Maggi 2-Minute Noodles 280 g","Nestle",56,280),("Kellogg's Corn Flakes 475 g","Kellogg's",210,475),("Quaker Oats 1 kg","Quaker",199,1000),
     ("Yippee Noodles Pack of 4","Sunfeast",60,240),("MTR Rava Idli Mix 500 g","MTR",120,500),("Kissan Mixed Fruit Jam 500 g","Kissan",165,500),
     ("Sundrop Peanut Butter 462 g","Sundrop",225,462),("Chings Schezwan Noodles 240 g","Ching's",60,240)],
 9: [("Dove Shampoo 340 ml","Dove",325,340),("Colgate Strong Teeth 200 g","Colgate",110,200),("Dettol Soap Pack of 4","Dettol",190,500),
     ("Nivea Body Lotion 400 ml","Nivea",399,400),("Gillette Guard Razor","Gillette",30,20),("Whisper Ultra XL 15 pcs","Whisper",199,300),
     ("Himalaya Face Wash 150 ml","Himalaya",185,150),("Pears Soap Pack of 3","Pears",165,375)],
 10:[("Surf Excel Easy Wash 1 kg","Surf Excel",140,1000),("Vim Dishwash Liquid 500 ml","Vim",115,500),("Harpic Toilet Cleaner 500 ml","Harpic",99,500),
     ("Lizol Floor Cleaner 975 ml","Lizol",215,975),("Good Knight Refill","Good Knight",85,45),("Scotch-Brite Scrub Pad 3 pcs","Scotch-Brite",60,60),
     ("Garbage Bags Medium 30 pcs","Ezee",99,300)],
 11:[("Pampers Pants M 56 pcs","Pampers",999,1500),("Huggies Wipes 72 pcs","Huggies",199,400),("Cerelac Wheat Apple 300 g","Nestle",285,300),
     ("Johnson's Baby Powder 200 g","Johnson's",165,200),("Himalaya Baby Lotion 200 ml","Himalaya",175,200)],
 12:[("Tata Tea Gold 500 g","Tata Tea",285,500),("Nescafe Classic 50 g","Nescafe",190,50),("Bru Instant Coffee 100 g","Bru",270,100),
     ("Horlicks Classic Malt 500 g","Horlicks",285,500),("Bournvita 500 g","Cadbury",245,500),("Red Label Tea 250 g","Brooke Bond",150,250),
     ("Green Tea Lipton 25 bags","Lipton",165,50)],
}
products = []  # id, name, cat_id, brand, mrp, cost, weight
pid = 101
for cid, items in P.items():
    margin = categories[cid-1][3]
    for name, brand, mrp, wt in items:
        disc = categories[cid-1][2]
        sp = mrp * (1 - disc/100)
        cost = round(sp * (1 - (margin + random.uniform(-4, 4))/100), 2)
        products.append([pid, name, cid, brand, mrp, cost, wt])
        pid += 1

# messy: a few missing brands
for p in random.sample(products, 3):
    p[3] = None

# ---------------- dark stores ----------------
cities = {"Bengaluru": ["Koramangala","HSR Layout","Indiranagar","Whitefield","Jayanagar"],
          "Mumbai": ["Andheri West","Powai","Bandra","Thane West"],
          "Delhi NCR": ["Gurugram Sector 45","Noida Sector 62","Saket","Dwarka"],
          "Hyderabad": ["Gachibowli","Madhapur","Kondapur"],
          "Pune": ["Kothrud","Baner","Viman Nagar"],
          "Chennai": ["Velachery","Anna Nagar","OMR"]}
city_weight = {"Bengaluru":30,"Mumbai":24,"Delhi NCR":20,"Hyderabad":11,"Pune":8,"Chennai":7}
stores = []
sid = 1
for c, areas in cities.items():
    for a in areas:
        stores.append([sid, f"ZPT-{c[:3].upper()}-{sid:02d}", c, a, date(2022,1,1)+timedelta(days=random.randint(0,700))])
        sid += 1

# ---------------- customers ----------------
first = ["Aarav","Vivaan","Aditya","Arjun","Rohan","Karthik","Rahul","Siddharth","Varun","Nikhil","Ananya","Diya","Priya","Sneha",
         "Kavya","Meera","Pooja","Isha","Riya","Neha","Shreya","Aditi","Manish","Suresh","Deepak","Akash","Harsha","Lakshmi","Divya","Tanvi",
         "Yash","Kunal","Ishaan","Sanjana","Bhavana","Rakesh","Pranav","Tejas","Swati","Nisha"]
last = ["Sharma","Verma","Iyer","Reddy","Nair","Patel","Gupta","Rao","Kulkarni","Menon","Joshi","Shetty","Hegde","Singh","Mehta",
        "Desai","Pillai","Chopra","Agarwal","Bhat","Naidu","Kapoor","Das","Mishra","Gowda"]
city_variants = {"Bengaluru":["Bengaluru","Bengaluru","Bengaluru","bengaluru","Bangalore","BENGALURU "],
                 "Mumbai":["Mumbai","Mumbai","Mumbai","mumbai","Bombay"],
                 "Delhi NCR":["Delhi NCR","Delhi NCR","Delhi NCR","delhi ncr","Delhi"],
                 "Hyderabad":["Hyderabad","Hyderabad","hyderabad "],
                 "Pune":["Pune","Pune","PUNE"],"Chennai":["Chennai","Chennai","chennai"]}
customers = []
cust_city = {}
N_CUST = 2000
for i in range(1, N_CUST+1):
    c = random.choices(list(city_weight), weights=city_weight.values())[0]
    f, l = random.choice(first), random.choice(last)
    email = f"{f.lower()}.{l.lower()}{random.randint(1,999)}@{random.choice(['gmail.com','gmail.com','yahoo.com','outlook.com'])}"
    if random.random() < 0.04: email = None
    phone = f"9{random.randint(100000000,999999999)}" if random.random() > 0.02 else None
    signup = date(2023,1,1) + timedelta(days=int(random.triangular(0, 880, 700)))
    customers.append([1000+i, f"{f} {l}", email, phone, random.choice(city_variants[c]), signup])
    cust_city[1000+i] = c
# messy: duplicate customer rows
for c in random.sample(customers, 8):
    customers.append(list(c))

# customer loyalty: some customers order far more
cust_weight = {c[0]: random.paretovariate(1.6) for c in customers[:N_CUST]}
stores_by_city = {}
for s in stores: stores_by_city.setdefault(s[2], []).append(s[0])

# ---------------- orders ----------------
start = datetime(2025,1,1)
end = datetime(2025,6,30,23,59)
month_growth = {1:1.0,2:1.06,3:1.15,4:1.22,5:1.33,6:1.40}
hour_w = [1,0.5,0.3,0.2,0.2,0.4,1.5,3.5,5,4.5,3.5,3.2,3.5,3,2.5,2.6,3.2,4.5,6,7.5,7,5.5,3.5,2]
summer_boost = {4:{4:1.6,5:2.0},5:{4:2.0,5:2.8},6:{4:1.8,5:2.3}}  # month -> cat -> factor
cat_weights = {c[0]: c[4] for c in categories}
prods_by_cat = {}
for p in products: prods_by_cat.setdefault(p[2], []).append(p)
pmap = {p[0]: p for p in products}

orders, items = [], []
oid, iid = 500001, 1
day = start
cust_ids = list(cust_weight); cw = list(cust_weight.values())
while day <= end:
    m = day.month
    wkend = 1.25 if day.weekday() >= 5 else 1.0
    n = int(random.gauss(44, 5) * month_growth[m] * wkend)
    for _ in range(max(n, 10)):
        cid = random.choices(cust_ids, weights=cw)[0]
        if customers[cid-1001][5] > day.date():
            continue
        city = cust_city[cid]
        store = random.choice(stores_by_city[city])
        hr = random.choices(range(24), weights=hour_w)[0]
        ts = day.replace(hour=hr, minute=random.randint(0,59), second=random.randint(0,59))
        pay = random.choices(["UPI","Credit Card","Debit Card","Cash on Delivery","Wallet"], weights=[62,12,9,11,6])[0]
        status = random.choices(["Delivered","Cancelled","Returned"], weights=[92,5.5,2.5])[0]
        peak = 3 if hr in (8,9,19,20,21) else 0
        dtime = max(5, int(random.gauss(11 + peak + (2 if city in ("Mumbai","Delhi NCR") else 0), 3)))
        if status == "Cancelled": dtime = None
        elif random.random() < 0.01: dtime = None  # messy: missing values
        # items
        n_items = random.choices([1,2,3,4,5,6,7,8], weights=[12,20,22,17,12,8,5,4])[0]
        cw_m = {k: v * summer_boost.get(m, {}).get(k, 1) for k, v in cat_weights.items()}
        chosen = set()
        basket = []
        for _ in range(n_items):
            cat = random.choices(list(cw_m), weights=cw_m.values())[0]
            p = random.choice(prods_by_cat[cat])
            if p[0] in chosen: continue
            chosen.add(p[0])
            qty = random.choices([1,2,3,4], weights=[70,20,7,3])[0]
            base = categories[cat-1][2]
            disc = max(0, round(random.choice([base-5, base, base, base+5, base+10]) + (5 if m == 1 and day.day <= 3 else 0)))
            disc = min(disc, 50)
            price = round(p[4] * (1 - disc/100), 2)
            basket.append([iid, oid, p[0], qty, p[4], disc, price])
            iid += 1
        if not basket: continue
        subtotal = sum(b[3]*b[6] for b in basket)
        fee = 0 if subtotal >= 199 else 30
        orders.append([oid, cid, store, ts.strftime("%Y-%m-%d %H:%M:%S"), pay, status, dtime, fee])
        items.extend(basket)
        oid += 1
    day += timedelta(days=1)

# messy: duplicated order_item rows
for it in random.sample(items, 15):
    items.append(list(it))
    items[-1][0] = iid; iid += 1
# messy: a few zero / negative quantities
for it in random.sample(items, 6):
    it[3] = random.choice([0, -1])

# ---------------- write CSVs ----------------
tables = {
 "categories": (["category_id","category_name"], [[c[0], c[1]] for c in categories]),
 "products": (["product_id","product_name","category_id","brand","mrp","cost_price","weight_in_gms"], products),
 "dark_stores": (["store_id","store_code","city","area","opened_on"], stores),
 "customers": (["customer_id","customer_name","email","phone","city","signup_date"], customers),
 "orders": (["order_id","customer_id","store_id","order_datetime","payment_method","order_status","delivery_time_mins","delivery_fee"], orders),
 "order_items": (["order_item_id","order_id","product_id","quantity","mrp","discount_percent","selling_price"], items),
}
for name, (hdr, rows) in tables.items():
    with open(f"{OUT}/{name}.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f); w.writerow(hdr)
        for r in rows: w.writerow(["" if v is None else v for v in r])
    print(name, len(rows))

# ---------------- write full SQL load script ----------------
ddl = """-- =====================================================
-- Zepto Sales Analysis - simulated dataset (Jan-Jun 2025)
-- Creates the database, all 6 tables, and loads the data.
-- Run the whole file in MySQL Workbench (Ctrl + Shift + Enter).
-- NOTE: this is SIMULATED data for learning, not real Zepto data.
-- =====================================================

DROP DATABASE IF EXISTS zepto_sales;
CREATE DATABASE zepto_sales;
USE zepto_sales;

CREATE TABLE categories (
    category_id     INT PRIMARY KEY,
    category_name   VARCHAR(60) NOT NULL
);

CREATE TABLE products (
    product_id      INT PRIMARY KEY,
    product_name    VARCHAR(120) NOT NULL,
    category_id     INT,
    brand           VARCHAR(60),
    mrp             DECIMAL(8,2),
    cost_price      DECIMAL(8,2),
    weight_in_gms   INT,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE TABLE dark_stores (
    store_id        INT PRIMARY KEY,
    store_code      VARCHAR(20),
    city            VARCHAR(40),
    area            VARCHAR(60),
    opened_on       DATE
);

-- No primary key on customers on purpose: the raw data has duplicates to clean in Level 4
CREATE TABLE customers (
    customer_id     INT,
    customer_name   VARCHAR(80),
    email           VARCHAR(120),
    phone           VARCHAR(15),
    city            VARCHAR(40),
    signup_date     DATE
);

CREATE TABLE orders (
    order_id            INT PRIMARY KEY,
    customer_id         INT,
    store_id            INT,
    order_datetime      DATETIME,
    payment_method      VARCHAR(30),
    order_status        VARCHAR(20),
    delivery_time_mins  INT,
    delivery_fee        DECIMAL(6,2),
    FOREIGN KEY (store_id) REFERENCES dark_stores(store_id)
);

CREATE TABLE order_items (
    order_item_id       INT PRIMARY KEY,
    order_id            INT,
    product_id          INT,
    quantity            INT,
    mrp                 DECIMAL(8,2),
    discount_percent    DECIMAL(5,2),
    selling_price       DECIMAL(8,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
"""
def sqlval(v):
    if v is None: return "NULL"
    if isinstance(v, (int, float)): return str(v)
    return "'" + str(v).replace("'", "''") + "'"

with open(f"{OUT}/zepto_sales_setup.sql", "w", encoding="utf-8") as f:
    f.write(ddl)
    for name, (hdr, rows) in tables.items():
        f.write(f"\n-- ---------- {name} ({len(rows)} rows) ----------\n")
        for i in range(0, len(rows), 500):
            chunk = rows[i:i+500]
            f.write(f"INSERT INTO {name} ({', '.join(hdr)}) VALUES\n")
            f.write(",\n".join("(" + ", ".join(sqlval(v) for v in r) + ")" for r in chunk))
            f.write(";\n")
    f.write("\n-- Quick check\nSELECT 'categories' AS tbl, COUNT(*) FROM categories UNION ALL\n"
            "SELECT 'products', COUNT(*) FROM products UNION ALL\nSELECT 'dark_stores', COUNT(*) FROM dark_stores UNION ALL\n"
            "SELECT 'customers', COUNT(*) FROM customers UNION ALL\nSELECT 'orders', COUNT(*) FROM orders UNION ALL\n"
            "SELECT 'order_items', COUNT(*) FROM order_items;\n")
print("done")
