#!/bin/bash

input_jsonl="/mnt/c/WOLF/Logs/Hayabusa/results.jsonl"
output_dir="/mnt/c/WOLF/Logs/Hayabusa/chunks"
lines_per_chunk=2000  # Set chunk size

mkdir -p "$output_dir"

# Convert input JSONL to NDJSON
jq -Rs 'split("\n")[] | select(length>0) | fromjson? | ({"index":{"_index":"hayabusa"}}), .' "$input_jsonl" | \
jq -s -c '.[]' > "/mnt/c/WOLF/Logs/Hayabusa/results.ndjson"

# Split the NDJSON file into chunks with proper line pairs
split -l $lines_per_chunk --numeric-suffixes=1 --additional-suffix=.ndjson "/mnt/c/WOLF/Logs/Hayabusa/results.ndjson" "${output_dir}/results_chunk_"