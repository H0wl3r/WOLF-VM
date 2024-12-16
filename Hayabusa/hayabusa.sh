#!/bin/bash
jq -Rs 'split("\n")[] | select(length>0) | fromjson? | ({"index":{"_index":"hayabusa"}}), .' /mnt/c/WOLF/Logs/Hayabusa/results.jsonl > /mnt/c/WOLF/Logs/Hayabusa/results.json; 
jq -s -c '.[]' /mnt/c/WOLF/Logs/Hayabusa/results.json > /mnt/c/WOLF/Logs/Hayabusa/results.ndjson;