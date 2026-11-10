p = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\affiliate\presentation\affiliate_hub_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Swap tabs in TabBar
text = text.replace("""                  tabs: const [
                    Tab(text: 'Performa & CVR'),
                    Tab(text: 'Katalog Cuan'),
                    Tab(text: 'Riwayat Penarikan'),
                  ],""", """                  tabs: const [
                    Tab(text: 'Katalog Cuan'),
                    Tab(text: 'Performa & CVR'),
                    Tab(text: 'Riwayat Penarikan'),
                  ],""")

# 2. Swap TabBarView children
text = text.replace("""        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCreatorVideosTab(isDark),
            _buildProductsTab(isDark),
            _buildWithdrawalHistoryTab(isDark),
          ],
        ),""", """        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductsTab(isDark),
            _buildCreatorVideosTab(isDark),
            _buildWithdrawalHistoryTab(isDark),
          ],
        ),""")

with open(p, 'w', encoding='utf-8') as f:
    f.write(text)

print("Updated tab order in affiliate_hub_screen.dart!")
