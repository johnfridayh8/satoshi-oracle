# SatoshiOracle

## Decentralized Bitcoin Price Prediction Protocol

A trustless prediction market protocol built on Stacks, enabling users to speculate on Bitcoin price movements while maintaining complete self-custody of their assets. SatoshiOracle harnesses the power of collective market intelligence through transparent, oracle-driven settlement mechanisms.

## 🚀 Core Innovation

SatoshiOracle eliminates traditional market maker dependencies by creating peer-to-peer prediction pools where participants stake STX tokens on Bitcoin price direction. Winners automatically receive proportional rewards from the losing side's pool, creating a zero-sum game with transparent economics.

## ✨ Features

- **Fully Non-Custodial**: Complete user sovereignty with no intermediaries
- **Atomic Settlement**: Secure, automated resolution via Stacks L2 smart contracts
- **Oracle Integration**: Programmable price feeds for accurate market resolution
- **Transparent Economics**: Clear fee structure with no hidden costs
- **Bitcoin-Native**: Designed specifically for the Stacks ecosystem

## 🏗️ System Overview

SatoshiOracle operates as a decentralized prediction market where users can take positions on Bitcoin price movements. The protocol creates time-bounded markets with opening and closing prices, allowing participants to stake STX tokens on whether Bitcoin will go up ("bull") or down ("bear") by the market's expiration.

### Key Components

1. **Market Creation**: Protocol owner creates markets with defined time windows
2. **Position Taking**: Users stake STX tokens on price direction predictions
3. **Oracle Settlement**: External oracle provides closing prices for resolution
4. **Reward Distribution**: Winners receive proportional payouts from losing positions

## 📊 Contract Architecture

### Core Data Structures

#### Markets Map

```clarity
{
  opening-price: uint,      // BTC/USD opening price (satoshis)
  closing-price: uint,      // BTC/USD closing price (satoshis)
  bull-commitment: uint,    // Total bullish positions (STX)
  bear-commitment: uint,    // Total bearish positions (STX)
  activation-block: uint,   // Market start block height
  expiration-block: uint,   // Market end block height
  resolution-status: bool,  // Settlement completion flag
}
```

#### Positions Map

```clarity
{
  direction: string-ascii,  // Position type: "bull" or "bear"
  amount: uint,            // STX amount committed
  claimed: bool,           // Reward claim status
}
```

### Configuration Variables

- **Oracle Address**: External price feed provider
- **Minimum Stake**: 1.0 STX minimum participation threshold
- **Protocol Fee**: 2% fee on winnings
- **Market Counter**: Global market ID tracking

## 🔄 Data Flow

### 1. Market Creation

```
Owner → create-market() → New Market ID
```

- Protocol owner creates market with opening price and time bounds
- Market receives unique ID and enters active state

### 2. Position Taking

```
User → take-position() → STX Transfer → Position Recorded
```

- Users stake STX tokens on "bull" or "bear" positions
- Stakes are transferred to contract custody
- Position details recorded in contract state

### 3. Market Settlement

```
Oracle → settle-market() → Closing Price → Market Resolved
```

- Oracle provides closing price after expiration
- Market status updated to resolved
- Winners determined based on price movement

### 4. Reward Distribution

```
Winner → claim-rewards() → Calculate Payout → STX Transfer
```

- Winners claim proportional rewards from losing pool
- Protocol fee deducted from gross winnings
- Net payout transferred to winner

## 🛠️ Core Functions

### Public Functions

#### Market Management

- `create-market(opening-price, activation-block, expiration-block)` - Creates new prediction market
- `settle-market(market-id, closing-price)` - Resolves market with final price

#### User Participation

- `take-position(market-id, position, stake)` - Takes bull/bear position
- `claim-rewards(market-id)` - Claims winnings from resolved market

#### Administration

- `update-oracle(new-oracle)` - Updates oracle address
- `adjust-minimum-stake(new-minimum)` - Modifies minimum stake requirement

### Read-Only Functions

- `get-market-data(market-id)` - Retrieves complete market information
- `get-user-position(market-id, user)` - Gets user position details
- `get-contract-balance()` - Returns current contract balance
- `get-protocol-config()` - Returns protocol configuration

## 🔐 Security Features

- **Owner-Only Functions**: Critical operations restricted to contract owner
- **Oracle Authentication**: Only designated oracle can settle markets
- **Input Validation**: Comprehensive parameter checking
- **Balance Verification**: Ensures sufficient funds before transfers
- **Claim Protection**: Prevents double-claiming of rewards

## 📈 Economic Model

### Reward Calculation

```
Gross Reward = (User Stake × Total Pool) ÷ Winning Pool
Protocol Fee = Gross Reward × 2%
Net Payout = Gross Reward - Protocol Fee
```

### Example Scenario

- Market: Will Bitcoin be above $50,000?
- Bull Pool: 1,000 STX, Bear Pool: 500 STX
- User: 100 STX on Bull (Bitcoin rises)
- User's Reward: (100 × 1,500) ÷ 1,000 = 150 STX
- Protocol Fee: 150 × 2% = 3 STX
- Net Payout: 147 STX

## 🚦 Error Codes

- `u100`: Owner-only operation
- `u101`: Invalid parameter
- `u102`: Market/position not found
- `u103`: Market closed or expired
- `u104`: Invalid prediction type
- `u105`: Insufficient balance
- `u106`: Rewards already claimed

## 🔧 Configuration

### Default Settings

- **Minimum Stake**: 1.0 STX
- **Protocol Fee**: 2%
- **Oracle Address**: Configurable by owner

### Deployment Requirements

- Stacks blockchain environment
- Oracle integration for price feeds
- Initial owner configuration

## 📋 Usage Example

```clarity
;; Create market (owner only)
(create-market u5000000000 u1000 u2000)

;; Take bull position
(take-position u0 "bull" u10000000)

;; Settle market (oracle only)
(settle-market u0 u5500000000)

;; Claim rewards
(claim-rewards u0)
```

## 🤝 Contributing

SatoshiOracle is designed for the Stacks ecosystem. Contributions should maintain the protocol's core principles of decentralization, transparency, and user sovereignty.

## ⚖️ License

This protocol is released under open-source principles, fostering innovation in decentralized prediction markets.
