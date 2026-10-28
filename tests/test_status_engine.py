import pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "reference_implementation"))
from status_engine import Order, classify


def test_not_provisioned():
    assert classify(Order(None, None)) == "Not provisioned"

def test_received_ok_within_tolerance():
    assert classify(Order(100.0, 99.5)) == "Received OK"

def test_received_above_provision():
    assert classify(Order(100.0, 130.0)) == "Received above provision"

def test_returned_with_positive_settlement_beats_everything_else():
    assert classify(Order(100.0, 130.0, returned=True)) == "Returned with positive settlement"

def test_cancelled_has_priority_over_pending():
    assert classify(Order(100.0, None, shipment_flag="CANCELLED")) == "Cancelled"

def test_pending_without_case():
    assert classify(Order(100.0, None)) == "Settlement pending"

def test_registered_case_beats_pending():
    assert classify(Order(100.0, None, case_class="in recovery")) == "Recovery case"

def test_zero_or_negative_settlement():
    assert classify(Order(100.0, -5.0)) == "Zero or negative"

def test_tolerance_is_configurable():
    assert classify(Order(100.0, 97.0), tolerance=5.0) == "Received OK"
    assert classify(Order(100.0, 97.0), tolerance=1.0) == "Review queue"
