## Description

#  Installation

1. Make sure to use node 12.12.0
2. Run `npm install` in project root directory
3. Create `.env` file:

```
PRIVATE_KEY="{YOUR_PRIVATE_KEY}"
FEE_LIMIT="{FEE_LIMIT}"
USER_FEE_PERCENTAGE="{USER_FEE_PERCENTAGE}"
TOKEN_USDT_ADDRESS="{TOKEN_USDT_ADDRESS}"
QUORUM_ADDRESS="{QUORUM_ADDRESS}"
PROXY_ADDRESS="{PROXY_ADDRESS}"
PREV_DAISY_ADDRESS="{PREV_DAISY_ADDRESS}"
NEW_DAISY_VERSION_1_ADDRESS="{NEW_DAISY_VERSION_1_ADDRESS}"
NEW_DAISY_VERSION_2_ADDRESS="{NEW_DAISY_VERSION_2_ADDRESS}"
```

4. Run `npx hardhat compile` in project root directory

# Run local tests
Run `npx hardhat test`.
To run specific test file use `npx hardhat test test/{filename.ts}`.
