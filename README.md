# Export Escrow Platform with STX Incentives

A decentralized escrow platform built on Stacks blockchain for export/import transactions with built-in STX incentive distribution system.

## 🚀 Features

- **Secure Escrow System**: Lock STX tokens in smart contracts until conditions are met
- **Multi-Party Workflow**: Supports business owners, logistics agents, and customers
- **Incentive Distribution**: Automatic STX rewards for all participants upon completion
- **Dispute Resolution**: Built-in dispute mechanism with admin resolution
- **Status Tracking**: Real-time tracking of escrow states (Open → Shipped → Completed)

## 📋 Smart Contract Functions

### Core Functions

1. **`create-escrow`** - Create a new escrow with locked STX
   - Parameters: `agent` (principal), `customer` (principal), `amount` (uint)
   - Returns: Escrow ID

2. **`confirm-shipment`** - Agent confirms goods shipment
   - Parameters: `escrow-id` (uint)
   - Access: Only designated agent

3. **`release-funds`** - Customer releases funds to complete transaction
   - Parameters: `escrow-id` (uint)
   - Access: Only designated customer
   - Triggers: STX transfer to owner + incentive distribution

4. **`raise-dispute`** - Raise a dispute on an escrow
   - Parameters: `escrow-id` (uint), `reason` (string-ascii 128)
   - Access: Owner or customer only

5. **`resolve-dispute`** - Admin resolves disputes
   - Parameters: `escrow-id` (uint), `release-to-owner` (bool)
   - Access: Contract deployer only

6. **`get-escrow`** - Read escrow details (read-only)
   - Parameters: `escrow-id` (uint)
   - Returns: Escrow data or error

## 💰 Incentive System

- **Owner Incentive**: 1 STX (1,000,000 micro-STX)
- **Agent Incentive**: 0.5 STX (500,000 micro-STX)
- **Customer Incentive**: 0.25 STX (250,000 micro-STX)

## 🔧 Development Setup

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet/introduction) - Stacks smart contract development tool
- Node.js and npm (for testing)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/lanre768/Export_Escrow-STX-Incentives.git
cd Export_Escrow-STX-Incentives
```

2. Install dependencies:
```bash
npm install
```

3. Check smart contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

## 🧪 Testing

The project uses Vitest with Clarinet SDK for testing. Test files are located in the `tests/` directory.

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:report

# Watch mode for development
npm run test:watch
```

## 📁 Project Structure

```
Export_Escrow-STX-Incentives/
├── contracts/
│   └── export_escrow.clar          # Main escrow smart contract
├── tests/
│   └── export_escrow.test.ts       # Test suite
├── settings/
│   ├── Devnet.toml                 # Devnet configuration
│   ├── Testnet.toml                # Testnet configuration
│   └── Mainnet.toml                # Mainnet configuration
├── Clarinet.toml                   # Clarinet project configuration
├── package.json                    # Node.js dependencies
├── tsconfig.json                   # TypeScript configuration
└── vitest.config.js                # Test configuration
```

## 🔐 Error Codes

- `u1` - ERR_AMOUNT_INVALID: Invalid amount provided
- `u100` - ERR_UNAUTHORIZED: Unauthorized access
- `u101` - ERR_NOT_DISPUTED: Escrow is not in disputed state
- `u102` - ERR_ESCROW_NOT_FOUND: Escrow does not exist
- `u103` - ERR_INVALID_STATUS: Invalid escrow status for operation

## 🌐 Deployment

### Devnet Deployment
```bash
clarinet integrate
```

### Testnet/Mainnet Deployment
Configure your deployment settings in the respective `.toml` files in the `settings/` directory.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📄 License

This project is licensed under the ISC License.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarinet Documentation](https://docs.hiro.so/clarinet/introduction)
- [Clarity Language Reference](https://docs.stacks.co/clarity/language-overview)
