# BeamVest

A decentralized lending and borrowing protocol built natively on the [Beam Network](https://onbeam.com). BeamVest allows $BEAM holders to deposit and earn yield, while borrowers can access liquidity by posting collateral — all governed by transparent, on-chain smart contracts with no intermediaries.

**Status:** MVP deployed on Beam Testnet. Full protocol in active development.

---

## How It Works

### For Lenders

Deposit native $BEAM into the pool and earn yield automatically. Interest accrues in real time based on how much of the pool is currently being borrowed (utilization rate). Withdraw your deposit plus earned interest at any time.

### For Borrowers

Post at least **150% of your desired loan value** as collateral to borrow $BEAM. Your collateral is locked in the contract and returned when you repay. This lets you access liquidity without selling your $BEAM holdings.

### Liquidation

If a borrower's collateral value drops below **125%** of their loan, the position becomes liquidatable. Any user can repay the debt on behalf of the borrower and receive the collateral at a **5% discount** as a reward. This protects lenders at all times.

### Interest Rates

Rates are set automatically by the protocol based on pool utilization — the percentage of deposited funds currently borrowed. Higher utilization = higher rates to attract more deposits. Lower utilization = lower rates to encourage borrowing.

---

## Contract

|                      |                                              |
| -------------------- | -------------------------------------------- |
| **Network**          | Beam Testnet (Chain ID: 13337)               |
| **Contract Address** | `0x4Dcd7546665Bd2dA49AF4E60Bb5Ab6e62f09b0f1` |
| **Solidity Version** | 0.8.28                                       |
| **License**          | MIT                                          |

### Core Functions

| Function              | Who      | Description                                |
| --------------------- | -------- | ------------------------------------------ |
| `deposit()`           | Lender   | Deposit native $BEAM to earn yield         |
| `withdraw(amount)`    | Lender   | Withdraw deposit + accrued interest        |
| `borrow(amount)`      | Borrower | Post collateral (msg.value), borrow $BEAM  |
| `repay()`             | Borrower | Repay loan (msg.value), recover collateral |
| `liquidate(borrower)` | Anyone   | Liquidate undercollateralised position     |

### View Functions

| Function                | Returns                                     |
| ----------------------- | ------------------------------------------- |
| `utilizationRate()`     | % of pool currently borrowed (0–100)        |
| `currentAPY()`          | Current borrow/lend APY                     |
| `healthFactor(address)` | Borrower health — below 125 is liquidatable |
| `amountOwed(address)`   | Total repayment due (principal + interest)  |

---

## Security

- **ReentrancyGuard** — all state-changing functions protected against reentrancy attacks
- **Checks-Effects-Interactions** — state is updated before any external transfers
- **Safe native transfers** — uses low-level `.call{value}` instead of `.transfer()`
- **Custom errors** — gas-efficient error handling throughout

---

## Getting Started

### Prerequisites

- Node.js v18+
- pnpm
- A wallet with testnet $BEAM ([get some here](https://faucet.onbeam.com))

### Install

```bash
git clone https://github.com/yourusername/BeamVest
cd BeamVest
pnpm install
```

### Configure

Create a `.env` file in the project root:

```bash
PRIVATE_KEY=your_wallet_private_key_here
```

> Never commit your `.env` file. It is already in `.gitignore`.

### Compile

```bash
npx hardhat compile
```

### Deploy to Beam Testnet

```bash
npx hardhat ignition deploy ignition/modules/BeamVestModule.js --network beamTestnet
```

### Verify Contract

```bash
npx hardhat verify --network beamTestnet 0x4Dcd7546665Bd2dA49AF4E60Bb5Ab6e62f09b0f1
```

---

## Network Details

| | Testnet | Mainnet |
| **Chain ID** | 13337 | 4337 |
| **RPC URL** | `https://build.onbeam.com/rpc/testnet` | `https://build.onbeam.com/rpc` |
| **Explorer** | [subnets-test.avax.network/beam](https://subnets-test.avax.network/beam) | [subnets.avax.network/beam](https://subnets.avax.network/beam) |
| **Faucet** | [faucet.onbeam.com](https://faucet.onbeam.com) | — |

---

## Roadmap

- [x] Core lending pool (deposit, withdraw)
- [x] Collateralized borrowing
- [x] Algorithmic interest rates
- [x] Liquidation engine
- [x] Beam Testnet deployment
- [ ] Price oracle integration (Chainlink / TWAP)
- [ ] USDC pool support
- [ ] Frontend dashboard
- [ ] Full security audit
- [ ] Beam Mainnet deployment

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---

## License

[MIT](LICENSE)

---

Built for the [Beam Network](https://onbeam.com) ecosystem.
