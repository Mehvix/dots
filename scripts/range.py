#!/usr/bin/env python3

import re
import argparse

parser = argparse.ArgumentParser(description='Find range of some integers.')
parser.add_argument(
    'integers',
    metavar='N',
)

args = parser.parse_args()

range = lambda x: max(x) - min(x)

if __name__ == "__main__":
    tin = args.integers.strip()
    lst = re.compile(r'[\s]+').split(tin)
    n = [float(n) for n in lst]
    print("min:\t", min(n))
    print("max:\t", max(n))
    print("delta:\t", range(n))
    print("cycles:\t", len(n) / len(set(n)))
