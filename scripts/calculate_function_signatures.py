import glob
import json
import os
from typing import List
from web3 import Web3

def calculateSelector(sig):
    result = Web3.keccak(text=sig)
    selector = (Web3.to_hex(result))[:10]
    return selector

def getTypeFromInput(ipt: dict) -> str:
    components: List[dict] | None = ipt.get('components')
    if components:
        return f"({','.join([getTypeFromInput(c) for c in components])})"
    return ipt['type']

def process_file(fname):
    print(f"File: {fname}")
    with open(fname, "r") as f:
        js = json.loads(f.read())
    abi = js["abi"]
    
    functions = []
    events = []
    
    for item in abi:
        if not item.get('name'):
            continue
        
        name = item['name']
        inputs = item.get('inputs', [])
        signature = f"{name}({','.join([getTypeFromInput(x) for x in inputs])})"
        selector = calculateSelector(signature)
        
        if item['type'] == 'function':
            functions.append(f"  {signature} {selector}")
        elif item['type'] == 'event':
            events.append(f"  {signature} {selector}")
    
    if functions:
        print("Functions:")
        print("\n\n".join(functions))
        print()
    
    if events:
        print("Events:")
        print("\n\n".join(events))
        print()
    
    print()

# Filter out files from folders containing 't.sol'
json_files = [f for f in glob.glob("../out/*/*.json") if 't.sol' not in os.path.dirname(f)]

for fname in json_files:
    process_file(fname)