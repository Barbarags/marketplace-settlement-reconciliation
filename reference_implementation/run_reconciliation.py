"""Joins synthetic provisions with settlements and prints the status distribution."""
import csv, collections, pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from status_engine import Order, classify

DATA = pathlib.Path(__file__).resolve().parent.parent / "sample_data"
settled = {r["order_id"]: float(r["settlement_final"]) for r in csv.DictReader(open(DATA / "settlements.csv", encoding="utf-8"))}
counts, by_channel, rows = collections.Counter(), collections.defaultdict(collections.Counter), []
for r in csv.DictReader(open(DATA / "orders_provision.csv", encoding="utf-8")):
    o = Order(float(r["prov_settlement"]), settled.get(r["order_id"]), r["shipment_flag"], r["case_class"], r["returned"] == "True")
    s = classify(o)
    counts[s] += 1; by_channel[r["channel"]][s] += 1
    rows.append({**r, "status": s})
with open(DATA / "reconciliation_result.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys()); w.writeheader(); w.writerows(rows)
total = sum(counts.values())
print(f"{'Status':38}{'Orders':>8}{'%':>8}")
for s, n in counts.most_common():
    print(f"{s:38}{n:>8}{n/total:>8.1%}")
