"""Reference implementation of the settlement-reconciliation status waterfall.

Mirrors the logic of the Power Query M engine in ../power-query/04_*.m using
only synthetic data. The first matching rule wins (a strict hierarchy), which
makes every order land in exactly one status.
"""
from __future__ import annotations
from dataclasses import dataclass
from typing import Optional

DEFAULT_TOLERANCE = 1.00  # R$; mirrors CONFIG_CONCILIACAO[MARGEM_TOLERANCIA]


@dataclass
class Order:
    provision_final: Optional[float]      # expected net settlement (None = not provisioned)
    settlement_final: Optional[float]     # received net settlement (None = not settled yet)
    shipment_flag: str = ""               # e.g. CANCELLED, NOT_SHIPPED
    case_class: str = ""                  # last case-management classification
    returned: bool = False                # credit note found in ERP


# case-management keyword -> status (Level 3, evaluated in this order)
CASE_RULES = [
    ("MANUAL RECONCILED", "Justified"),
    ("DATA TICKET - PENDING", "Data ticket - pending"),
    ("DATA TICKET - REVERSAL", "Data ticket - reversal"),
    ("DATA TICKET - NOT REIMBURSED", "Data ticket - not reimbursed"),
    ("DATA TICKET - OTHER", "Data ticket - other"),
    ("DAMAGE", "Damage recovery"),
    ("IN RECOVERY", "Recovery case"),
    ("RECOVERED CUSTOMER", "Recovered - customer"),
    ("RECOVERED CARRIER", "Recovered - carrier"),
    ("RECOVERED MARKETPLACE", "Recovered - marketplace"),
    ("RECOVERED DATA", "Recovered - data team"),
]


def classify(o: Order, tolerance: float = DEFAULT_TOLERANCE) -> str:
    prov = o.provision_final or 0.0
    rec = o.settlement_final or 0.0
    diff = abs(prov - rec)
    provisioned = o.provision_final is not None
    settled = o.settlement_final is not None
    case = (o.case_class or "").upper()
    flag = (o.shipment_flag or "").upper()

    physically_returned = o.returned or "RETURN" in case
    settled_above = settled and provisioned and rec > prov and diff > tolerance
    settled_ok = settled and diff <= tolerance

    # Level 0 - nothing expected, nothing received
    if not provisioned and not settled:
        return "Not provisioned"
    # Level 1A - physical/financial conflict
    if physically_returned and settled_above:
        return "Returned with positive settlement"
    # Level 1 - physical status closed
    if flag == "CANCELLED" or "BLOCKED" in case or "CANCELLATION" in case:
        return "Cancelled"
    if flag == "NOT_SHIPPED":
        return "Not shipped"
    if physically_returned:
        return "Returned"
    # Level 2 - financially resolved
    if settled_above:
        return "Received above provision"
    if settled_ok:
        return "Received OK"
    if settled and rec <= 0:
        return "Zero or negative"
    # Level 3 - handling already registered
    for keyword, status in CASE_RULES:
        if keyword in case and not (keyword == "DATA TICKET - PENDING" and settled):
            return status
    # Level 4 - pending, no handling yet
    if not settled:
        return "Settlement pending"
    return "Review queue"
