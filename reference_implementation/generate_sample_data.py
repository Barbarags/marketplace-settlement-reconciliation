"""Generates a small, fully synthetic dataset (no real orders, values or partners)."""
import csv, random, pathlib

random.seed(42)
OUT = pathlib.Path(__file__).resolve().parent.parent / "sample_data"
OUT.mkdir(exist_ok=True)
CHANNELS = {"MAG": 0.16, "MELI": 0.14, "SHO": 0.18, "AMZ": 0.15, "TIK": 0.18, "VIA": 0.16, "B2W": 0.15, "FOU": 0.10}
CASES = ["", "", "", "", "IN RECOVERY", "DAMAGE", "DATA TICKET - PENDING", "MANUAL RECONCILED",
         "RECOVERED CARRIER", "CANCELLATION", "RETURN - CARRIER"]

orders, settlements = [], []
for i in range(1, 801):
    ch = random.choice(list(CHANNELS))
    gross = round(random.uniform(40, 2500), 2)
    commission = round(gross * CHANNELS[ch], 2)
    freight = round(random.uniform(0, 70), 2)
    fixed = random.choice([0, 0, 5, 6])
    prov = round(gross - commission - freight - fixed, 2)
    oid = f"ORD-{i:06d}"
    flag = random.choices(["", "CANCELLED", "NOT_SHIPPED"], [92, 5, 3])[0]
    case = random.choice(CASES)
    orders.append(dict(order_id=oid, channel=ch, gross=gross, prov_commission=commission,
                       prov_freight=freight, prov_fixed_fee=fixed, prov_settlement=prov,
                       shipment_flag=flag, case_class=case, returned=random.random() < 0.04))
    if random.random() < 0.82:  # settled
        noise = random.choices([0, 1, 2], [70, 20, 10])[0]
        rec = prov if noise == 0 else round(prov + random.uniform(-45, 25), 2)
        if random.random() < 0.03:
            rec = round(random.uniform(-30, 0), 2)
        settlements.append(dict(order_id=oid, channel=ch, settlement_final=rec))

for name, rows in (("orders_provision.csv", orders), ("settlements.csv", settlements)):
    with open(OUT / name, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys()); w.writeheader(); w.writerows(rows)
print(f"orders={len(orders)} settlements={len(settlements)}")
