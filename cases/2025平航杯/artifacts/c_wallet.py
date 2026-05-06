#!/usr/bin/env python3
from eth_account import Account

Account.enable_unaudited_hdwallet_features()
mnemonic = "flash treat wide divide type plug garlic draft infant broom desert useful"
acct = Account.from_mnemonic(mnemonic)
print('Address:', acct.address)
print('Priv key:', acct.key.hex())
print('8th word (0-indexed 7):', mnemonic.split()[7])