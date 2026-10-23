#!/usr/bin/env python3
"""Write a SYNTHETIC Lightning payments CSV (columns modeled on an `lncli listpayments` export).
Deterministic (seeded). Not real payment data. Usage: gen_ln_payments.py > payments.csv"""
import csv, random, sys
r = random.Random(42); w = csv.writer(sys.stdout)
w.writerow(['payment_hash','creation_date','value_sat','fee_msat','status','failure_reason','htlc_attempts','memo'])
for i in range(3000):
    st = r.choices(['SUCCEEDED','FAILED','IN_FLIGHT'], [85, 13, 2])[0]
    fr = r.choice(['FAILURE_REASON_NO_ROUTE','FAILURE_REASON_INSUFFICIENT_BALANCE','FAILURE_REASON_TIMEOUT']) if st == 'FAILED' else 'FAILURE_REASON_NONE'
    w.writerow([f"{r.getrandbits(256):064x}", 1790000000 + i*600, r.choice([21,100,1000,2100,5000,21000,100000]), r.randint(0,4000) if st=='SUCCEEDED' else 0, st, fr, r.randint(1,6), r.choice(['zap','coffee','podcast boost','invoice #%d' % r.randint(100,999)])])
