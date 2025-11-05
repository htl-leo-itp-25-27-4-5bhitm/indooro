import json

# Correct path to your file
input_file = "app/assets/data/belegplan.json"
output_file = "demoproducts.ndjson"

with open(input_file, "r", encoding="utf-8") as f:
    data = json.load(f)

with open(output_file, "w", encoding="utf-8") as f:
    for item in data:
        action = {"index": {"_index": "products"}}
        f.write(json.dumps(action, ensure_ascii=False) + "\n")
        f.write(json.dumps(item, ensure_ascii=False) + "\n")

print(f"NDJSON created: {output_file}")
