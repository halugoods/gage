import re

with open(r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\core\network\gage_api_client.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Extract lines from 311 to 750
lines = text.splitlines()
func_lines = lines[310:750]
print(f"Total lines in mock fallback: {len(func_lines)}")

# Let's inspect the if conditions
for i, l in enumerate(func_lines):
    if 'if (merchantId' in l:
        print(f"Condition: {l.strip()}")
