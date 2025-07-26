# EnergyGrid-Exchange Smart Contract

A decentralized marketplace for trading structured energy grid data on the Stacks blockchain, built with Clarity smart contracts.

## Overview

EnergyGrid-Exchange enables energy companies, grid operators, researchers, and data providers to buy and sell structured energy data in a secure, transparent marketplace. The contract handles payments, access control, and maintains comprehensive statistics for all participants.

## Features

### Core Marketplace Functions
- **Data Listing**: Sellers can list energy datasets with metadata, pricing, and descriptions
- **Secure Purchasing**: Buyers purchase data access using STX tokens
- **Access Control**: Only purchasers can access their bought data
- **Automatic Payments**: Smart contract handles fee distribution and seller payments

### Data Management
- **Flexible Updates**: Sellers can modify prices, descriptions, and availability
- **Listing Control**: Activate/deactivate listings as needed
- **Metadata Storage**: IPFS-compatible hash storage for off-chain data

### Analytics & Statistics
- **Seller Metrics**: Track sales count, total revenue, and active listings
- **Buyer History**: Monitor purchase history and spending patterns
- **Market Insights**: Comprehensive marketplace analytics

## Contract Architecture

### Data Structures

#### Data Listings
```clarity
{
  seller: principal,
  title: (string-ascii 100),
  description: (string-ascii 500),
  data-type: (string-ascii 50),
  price: uint,
  metadata-hash: (string-ascii 64),
  active: bool,
  created-at: uint
}
```

#### Purchase Records
```clarity
{
  purchased-at: uint,
  price-paid: uint,
  access-granted: bool
}
```

### Fee Structure
- Default marketplace fee: **2.5%** (configurable by contract owner)
- Maximum fee limit: **10%**
- Automatic fee distribution to contract owner
- Seller receives: `listing_price - marketplace_fee`

## Public Functions

### For Data Sellers

#### `list-data`
List new energy data for sale
```clarity
(list-data 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (data-type (string-ascii 50))
  (price uint)
  (metadata-hash (string-ascii 64))
)
```

**Parameters:**
- `title`: Dataset name (max 100 characters)
- `description`: Detailed description (max 500 characters)
- `data-type`: Category (e.g., "consumption", "generation", "grid-load")
- `price`: Price in microSTX (1 STX = 1,000,000 microSTX)
- `metadata-hash`: IPFS hash or similar identifier for off-chain data

**Returns:** `(ok data-id)` - Unique identifier for the listing

#### `update-listing`
Modify existing data listing (seller only)
```clarity
(update-listing 
  (data-id uint)
  (new-price uint)
  (new-description (string-ascii 500))
  (active bool)
)
```

#### `deactivate-listing`
Remove listing from marketplace (seller only)
```clarity
(deactivate-listing (data-id uint))
```

### For Data Buyers

#### `purchase-data`
Buy access to energy data
```clarity
(purchase-data (data-id uint))
```

**Requirements:**
- Sufficient STX balance for purchase + fees
- Data listing must be active
- Cannot purchase same data twice

#### `get-data-access`
Retrieve metadata hash for purchased data
```clarity
(get-data-access (data-id uint))
```

**Returns:** `(ok metadata-hash)` - Access key for off-chain data

### Read-Only Functions

#### `get-data-listing`
Retrieve complete listing information
```clarity
(get-data-listing (data-id uint))
```

#### `get-seller-stats`
Get seller performance metrics
```clarity
(get-seller-stats (seller principal))
```

#### `get-buyer-stats`
Get buyer purchase history
```clarity
(get-buyer-stats (buyer principal))
```

#### `has-access`
Check if buyer has access to specific data
```clarity
(has-access (buyer principal) (data-id uint))
```

## Usage Examples

### Listing Energy Data

```clarity
;; List solar generation data
(contract-call? .energy-grid-exchange list-data
  "Solar Farm Q3 2024 Generation Data"
  "Hourly solar generation data from 500MW solar farm, includes weather correlations and efficiency metrics"
  "generation"
  u5000000  ;; 5 STX
  "QmX4e5f2g3h9i1j2k3l4m5n6o7p8q9r0s1t2u3v4w5x6y7z8"
)
```

### Purchasing Data

```clarity
;; Purchase data with ID 1
(contract-call? .energy-grid-exchange purchase-data u1)
```

### Accessing Purchased Data

```clarity
;; Get metadata hash for data access
(contract-call? .energy-grid-exchange get-data-access u1)
```

## Data Types Supported

Common energy data categories:
- **`consumption`**: Energy usage patterns, demand profiles
- **`generation`**: Solar, wind, hydro, thermal generation data
- **`grid-load`**: Network load balancing, peak demand data
- **`pricing`**: Energy market prices, tariff structures
- **`weather`**: Weather data correlated with energy production
- **`maintenance`**: Equipment maintenance schedules and records

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | `err-owner-only` | Function restricted to contract owner |
| u101 | `err-not-found` | Data listing or record not found |
| u102 | `err-insufficient-funds` | Insufficient STX balance |
| u103 | `err-unauthorized` | Access denied or unauthorized action |
| u104 | `err-already-exists` | Duplicate purchase attempt |
| u105 | `err-invalid-price` | Invalid price (must be > 0) |
| u106 | `err-data-not-available` | Data listing is inactive |

## Security Features

### Access Control
- Sellers can only modify their own listings
- Buyers can only access purchased data
- Contract owner has administrative privileges

### Payment Security
- Atomic transactions ensure payment and access grant together
- Automatic fee calculation and distribution
- No double-spending protection

### Emergency Controls
- Contract owner can revoke data access if needed
- Fee adjustment capabilities for market conditions

## Deployment Instructions

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet with STX for deployment

### Steps

1. **Clone and Setup**
```bash
git clone <repository-url>
cd energy-grid-exchange
clarinet check
```

2. **Test Locally**
```bash
clarinet test
```

3. **Deploy to Testnet**
```bash
clarinet deploy --testnet
```

4. **Deploy to Mainnet**
```bash
clarinet deploy --mainnet
```

## Testing

Run the test suite:
```bash
npm install
npm test
```

### Test Coverage
- ✅ Data listing functionality
- ✅ Purchase and access control
- ✅ Fee calculations
- ✅ Seller/buyer statistics
- ✅ Error handling
- ✅ Edge cases and security

## Gas Costs (Approximate)

| Function | Cost Range |
|----------|------------|
| `list-data` | 15,000 - 25,000 µSTX |
| `purchase-data` | 20,000 - 35,000 µSTX |
| `update-listing` | 10,000 - 20,000 µSTX |
| Read functions | 1,000 - 5,000 µSTX |

*Costs vary based on network congestion and data size*

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Write tests for new functionality
4. Ensure all tests pass: `clarinet test`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

