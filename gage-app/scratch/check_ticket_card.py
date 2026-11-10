path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\home\presentation\widgets\gage_ticket_voucher_card.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i in range(15, 60):
    print(lines[i].encode('ascii', errors='replace').decode('ascii'), end='')
