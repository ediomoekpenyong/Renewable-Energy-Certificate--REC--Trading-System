# Renewable Energy Certificate (REC) Trading System

A decentralized platform for trading Renewable Energy Certificates built on the Stacks blockchain using Clarity smart contracts.

## Overview

This system facilitates the buying and selling of clean energy credits, providing transparent pricing and market information while enabling corporate renewable energy procurement and supporting grid decarbonization.

## System Architecture

### Core Contracts

1. **REC Registry (`rec-registry.clar`)**
    - Manages REC creation, ownership, and metadata
    - Tracks energy source, generation date, and certificate validity
    - Handles REC retirement and transfer operations

2. **Trading Platform (`trading-platform.clar`)**
    - Facilitates buy and sell orders for RECs
    - Manages order matching and execution
    - Handles escrow and settlement processes

3. **Price Oracle (`price-oracle.clar`)**
    - Maintains current market prices for different REC types
    - Provides historical pricing data
    - Updates prices based on market activity

4. **Compliance Tracker (`compliance-tracker.clar`)**
    - Tracks renewable energy mandates and requirements
    - Monitors corporate compliance status
    - Manages penalty calculations for non-compliance

5. **Corporate Procurement (`corporate-procurement.clar`)**
    - Handles bulk REC purchases for corporations
    - Manages long-term procurement contracts
    - Automates compliance reporting

## Key Features

- **Transparent Pricing**: Real-time market prices with historical data
- **Automated Compliance**: Track and enforce renewable energy mandates
- **Corporate Procurement**: Streamlined bulk purchasing for businesses
- **REC Lifecycle Management**: From generation to retirement
- **Market Liquidity**: Efficient order matching and settlement

## REC Types Supported

- Solar Energy Certificates
- Wind Energy Certificates
- Hydroelectric Certificates
- Biomass Energy Certificates
- Geothermal Energy Certificates

## Getting Started

### Prerequisites

- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for transactions

### Installation

\`\`\`bash
git clone <repository-url>
cd rec-trading-system
npm install
clarinet check
\`\`\`

### Running Tests

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage Examples

### Creating a REC

\`\`\`clarity
(contract-call? .rec-registry create-rec
u1000 ;; MWh generated
"solar" ;; energy source
u1640995200 ;; generation timestamp
"Solar Farm Alpha" ;; facility name
)
\`\`\`

### Placing a Buy Order

\`\`\`clarity
(contract-call? .trading-platform place-buy-order
u100 ;; quantity
u50 ;; price per REC
"solar" ;; REC type
)
\`\`\`

### Checking Compliance Status

\`\`\`clarity
(contract-call? .compliance-tracker get-compliance-status tx-sender)
\`\`\`

## Contract Interactions

The contracts work together to provide a complete REC trading ecosystem:

1. RECs are created in the registry with verified metadata
2. Trading platform matches buy/sell orders
3. Price oracle provides market pricing information
4. Compliance tracker monitors regulatory requirements
5. Corporate procurement handles enterprise-level purchases

## Security Features

- Multi-signature requirements for large transactions
- Time-locked settlements to prevent fraud
- Automated compliance checks
- Audit trails for all REC transfers

## Compliance Standards

The system supports various renewable energy standards:
- Renewable Portfolio Standards (RPS)
- Voluntary Renewable Energy Markets
- Corporate Sustainability Goals
- Carbon Offset Programs

## API Reference

Each contract exposes public functions for:
- Creating and managing RECs
- Trading operations
- Price queries
- Compliance reporting
- Corporate procurement

## Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License.
