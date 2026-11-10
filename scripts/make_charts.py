"""
make_charts.py - builds the 5 report charts by querying the cleaned zepto_sales database
(run after sql/01-12). Needs: pandas, matplotlib, and the mysql command-line client.
Edit the mysql command below to add your password, e.g. ["mysql", "-u", "root", "-pYOURPASSWORD", ...]
"""
import subprocess, io
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

OUT = "reports/charts/"   # run from the project root
SURF, INK, INK2, GRID, MUTED = "#fcfcfb", "#0b0b0b", "#52514e", "#e6e5e1", "#c9c8c2"
BLUE, ORANGE, AQUA = "#2a78d6", "#eb6834", "#1baf7a"

def q(sql):
    r = subprocess.run(["mysql", "-u", "root", "zepto_sales", "-B", "-e", sql], capture_output=True, text=True, check=True)
    return pd.read_csv(io.StringIO(r.stdout), sep="\t")

plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 11, "axes.edgecolor": MUTED,
    "axes.labelcolor": INK2, "xtick.color": INK2, "ytick.color": INK2, "figure.facecolor": SURF,
    "axes.facecolor": SURF, "axes.spines.top": False, "axes.spines.right": False})

def title(fig, t, sub):
    fig.text(0.02, 0.97, t, fontsize=15, fontweight="bold", color=INK, va="top")
    fig.text(0.02, 0.905, sub, fontsize=11, color=INK2, va="top")

def save(fig, name):
    fig.savefig(OUT + name, dpi=160, facecolor=SURF)
    plt.close(fig)

# 1 Monthly revenue
m = q("SELECT sales_month, revenue, orders FROM vw_monthly_kpis ORDER BY sales_month")
m["label"] = pd.to_datetime(m.sales_month + "-01").dt.strftime("%b")
fig, ax = plt.subplots(figsize=(9, 5)); fig.subplots_adjust(top=0.80, left=0.08, right=0.97)
bars = ax.bar(m.label, m.revenue / 1e5, color=BLUE, width=0.6)
for b, v in zip(bars, m.revenue / 1e5):
    ax.text(b.get_x() + b.get_width()/2, v + 0.12, f"₹{v:.2f}L", ha="center", color=INK, fontsize=10)
ax.set_ylabel("Revenue (₹ lakh)"); ax.yaxis.grid(True, color=GRID); ax.set_axisbelow(True)
title(fig, "Revenue grew every month: +64% from January to June 2025", "Monthly revenue from delivered orders")
save(fig, "01_monthly_revenue.png")

# 2 Category revenue and margin (small multiples, shared order)
c = q("SELECT category_name, revenue, margin_pct FROM vw_category_performance ORDER BY revenue")
fig, (a1, a2) = plt.subplots(1, 2, figsize=(11, 6.2), sharey=True, gridspec_kw={"width_ratios": [1.4, 1]})
fig.subplots_adjust(top=0.83, left=0.24, right=0.97, wspace=0.08)
a1.barh(c.category_name, c.revenue / 1e5, color=BLUE, height=0.62)
for y, v in enumerate(c.revenue / 1e5): a1.text(v + 0.08, y, f"{v:.1f}", va="center", fontsize=9, color=INK2)
a1.set_xlabel("Revenue (₹ lakh)")
a2.barh(c.category_name, c.margin_pct, color=ORANGE, height=0.62)
for y, v in enumerate(c.margin_pct): a2.text(v + 0.4, y, f"{v:.1f}%", va="center", fontsize=9, color=INK2)
a2.set_xlabel("Gross margin (%)")
for a in (a1, a2): a.xaxis.grid(True, color=GRID); a.set_axisbelow(True); a.tick_params(axis="y", length=0)
title(fig, "Staples bring revenue; personal care and snacks bring margin", "Revenue and gross margin by category, Jan–Jun 2025")
save(fig, "02_category_revenue_margin.png")

# 3 Orders by hour
h = q("SELECT order_hour, COUNT(DISTINCT order_id) orders FROM vw_sales GROUP BY order_hour ORDER BY order_hour")
peak = h.order_hour.isin([8, 9, 19, 20, 21])
fig, ax = plt.subplots(figsize=(10, 5)); fig.subplots_adjust(top=0.80, left=0.08, right=0.97)
ax.bar(h.order_hour, h.orders, color=[BLUE if p else MUTED for p in peak], width=0.75)
ax.set_xticks(range(0, 24, 2)); ax.set_xticklabels([f"{x:02d}:00" for x in range(0, 24, 2)])
ax.set_ylabel("Delivered orders"); ax.yaxis.grid(True, color=GRID); ax.set_axisbelow(True)
ax.text(8.5, 640, "Morning peak\n~14.5 min delivery", ha="center", fontsize=9.5, color=INK)
ax.text(20, 950, "Evening peak\n~14.3 min delivery", ha="center", fontsize=9.5, color=INK)
ax.set_ylim(0, 1080)
title(fig, "Orders peak at 8–9 AM and 7–9 PM, and delivery slows by ~3 minutes",
      "Delivered orders by hour of day (peak hours highlighted); off-peak delivery averages ~11.5 min")
save(fig, "03_orders_by_hour.png")

# 4 Seasonality indexed to Jan = 100
s = q("""SELECT sales_month,
 SUM(CASE WHEN category_name='Ice Creams & Frozen' THEN quantity ELSE 0 END) ice,
 SUM(CASE WHEN category_name='Cold Drinks & Juices' THEN quantity ELSE 0 END) cold,
 SUM(CASE WHEN category_name NOT IN ('Ice Creams & Frozen','Cold Drinks & Juices') THEN quantity ELSE 0 END) other
 FROM vw_sales GROUP BY sales_month ORDER BY sales_month""")
lab = pd.to_datetime(s.sales_month + "-01").dt.strftime("%b")
fig, ax = plt.subplots(figsize=(9.5, 5.2)); fig.subplots_adjust(top=0.80, left=0.08, right=0.80)
for col, name, colr in [("ice", "Ice creams & frozen", BLUE), ("cold", "Cold drinks & juices", ORANGE), ("other", "All other categories", AQUA)]:
    idx = 100 * s[col] / s[col].iloc[0]
    ax.plot(lab, idx, color=colr, linewidth=2, marker="o", markersize=7, markeredgecolor=SURF, markeredgewidth=2, label=name)
    ax.text(5.15, idx.iloc[-1], f"{name}\n{idx.iloc[-1]:.0f}", va="center", fontsize=9.5, color=INK)
ax.set_ylabel("Units sold (January = 100)"); ax.yaxis.grid(True, color=GRID); ax.set_axisbelow(True)
ax.legend(frameon=False, loc="upper left", fontsize=9.5, labelcolor=INK2)
title(fig, "Summer more than triples ice cream demand", "Units sold per month, indexed to January = 100")
save(fig, "04_summer_seasonality.png")

# 5 City: revenue per store and delivery time
ct = q("""SELECT v.city, v.revenue_per_store, d.avg_del FROM vw_city_performance v JOIN
 (SELECT s.city, AVG(o.delivery_time_mins) avg_del FROM orders o JOIN dark_stores s USING(store_id) WHERE o.order_status='Delivered' GROUP BY s.city) d
 ON v.city=d.city ORDER BY v.revenue_per_store""")
fig, (a1, a2) = plt.subplots(1, 2, figsize=(11, 4.8), sharey=True)
fig.subplots_adjust(top=0.78, left=0.12, right=0.97, wspace=0.1)
a1.barh(ct.city, ct.revenue_per_store / 1e5, color=BLUE, height=0.6)
for y, v in enumerate(ct.revenue_per_store / 1e5): a1.text(v + 0.03, y, f"{v:.2f}", va="center", fontsize=9, color=INK2)
a1.set_xlabel("Revenue per store (₹ lakh)")
a2.barh(ct.city, ct.avg_del, color=ORANGE, height=0.6)
for y, v in enumerate(ct.avg_del): a2.text(v + 0.15, y, f"{v:.1f} min", va="center", fontsize=9, color=INK2)
a2.set_xlabel("Average delivery time (minutes)"); a2.set_xlim(0, 16.5)
for a in (a1, a2): a.xaxis.grid(True, color=GRID); a.set_axisbelow(True); a.tick_params(axis="y", length=0)
title(fig, "Chennai and Pune stores earn a third to half of Bengaluru's", "Revenue per dark store and average delivery time by city")
save(fig, "05_city_performance.png")
print("charts done")
