p = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\affiliate\presentation\affiliate_hub_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("context.read<WalletProvider>().topUp(amount, method: 'Komisi GAGE Cuan');", "context.read<WalletProvider>().topUp(amount);")
text = text.replace("(_, __, ___)", "(context, error, stackTrace)")

with open(p, 'w', encoding='utf-8') as f:
    f.write(text)

print("Fixed topUp call and underscores in affiliate_hub_screen.dart!")
