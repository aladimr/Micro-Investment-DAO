# Micro-Investment DAO Smart Contract

A decentralized autonomous organization (DAO) smart contract built on Stacks blockchain that enables small investors to pool resources and collectively fund community projects with proportional governance rights.

##  Overview

The Micro-Investment DAO allows individuals to make small investments and participate in funding community projects through democratic voting. Governance power is proportional to investment amounts, ensuring fair representation while enabling collective decision-making.

##  Key Features

- **Proportional Governance**: Voting power based on investment amount
- **Democratic Project Approval**: Community votes on project proposals
- **Transparent Funding**: All transactions and votes are on-chain
- **Flexible Investment**: Support minimum investment thresholds
- **Project Lifecycle Management**: Complete project tracking from proposal to completion
- **Emergency Controls**: Owner-level emergency functions for safety

##  Architecture

### Core Components

1. **Investment Management**: Track member investments and DAO treasury
2. **Project Proposals**: Create and manage funding proposals
3. **Voting System**: Democratic voting with proportional power
4. **Fund Distribution**: Automatic funding for approved projects
5. **Project Tracking**: Monitor project status and completion

### Data Structures

- **Investments**: Member investment amounts and join dates
- **Projects**: Project details, funding goals, and status
- **Votes**: Individual votes with voting power and timestamps
- **Voting Status**: Aggregate voting results and deadlines

##  Getting Started

### Prerequisites

- Stacks CLI installed
- Clarity development environment
- STX tokens for testing

### Deployment

1. Clone the repository
2. Deploy the contract to Stacks testnet/mainnet
3. Initialize with desired minimum investment amount

```bash
# Deploy contract
clarinet deploy --testnet

# Verify deployment
clarinet call-public-function micro-investment-dao get-total-dao-funds
```

## Usage Guide

### For Investors

#### 1. Join the DAO
```clarity
;; Invest minimum 1 STX to join DAO
(contract-call? .micro-investment-dao join-dao u1000000)
```

#### 2. Vote on Projects
```clarity
;; Vote yes on project ID 1
(contract-call? .micro-investment-dao vote-on-project u1 true)
```

#### 3. Invest in Funded Projects
```clarity
;; Additional investment in approved project
(contract-call? .micro-investment-dao invest-in-project u1 u500000)
```

### For Project Creators

#### 1. Create Project Proposal
```clarity
;; Propose new community project
(contract-call? .micro-investment-dao create-project 
  "Community Garden"
  "Build a sustainable community garden for local food production"
  u10000000  ;; 10 STX funding goal
  u1000)     ;; Deadline in blocks
```

#### 2. Mark Project Complete
```clarity
;; Mark your funded project as completed
(contract-call? .micro-investment-dao complete-project u1)
```

### For Administrators

#### Finalize Voting
```clarity
;; Close voting and fund approved projects
(contract-call? .micro-investment-dao finalize-project-voting u1)
```

## Function Reference

### Read-Only Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `get-investment` | Get investor's details | `investor: principal` |
| `get-project` | Get project information | `project-id: uint` |
| `get-total-dao-funds` | Get total DAO treasury | None |
| `get-voting-power` | Get voter's power | `investor: principal` |
| `get-project-vote` | Get specific vote | `project-id: uint, voter: principal` |
| `get-voting-status` | Get voting statistics | `project-id: uint` |

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `join-dao` | Invest and join DAO | `amount: uint` |
| `create-project` | Propose new project | `title, description, funding-goal, deadline` |
| `vote-on-project` | Vote on proposal | `project-id: uint, vote: bool` |
| `finalize-project-voting` | Close voting and fund | `project-id: uint` |
| `invest-in-project` | Additional project investment | `project-id: uint, amount: uint` |
| `complete-project` | Mark project complete | `project-id: uint` |

## Example Workflows

### Complete Project Funding Cycle

1. **Alice joins DAO** with 5 STX investment
2. **Bob proposes** community park project (20 STX goal)
3. **DAO members vote** on Bob's proposal
4. **Voting period ends**, project gets approved (>51% yes votes)
5. **Project automatically funded** from DAO treasury
6. **Bob completes** the park project
7. **Community benefits** from the funded project

### Governance Scenarios

- **High-stake investor**: 10 STX investment = 10x voting power
- **Equal participation**: Multiple 1 STX investors vote collectively
- **Consensus building**: Projects need >51% approval to get funded
- **Transparent process**: All votes and funding visible on-chain

## Security Features

### Access Controls
- Project creators can only complete their own projects
- Only DAO members can vote (must have investment)
- Emergency functions restricted to contract owner

### Validation Checks
- Minimum investment requirements
- Voting deadline enforcement
- Duplicate vote prevention
- Sufficient fund validation

### Emergency Measures
- Owner can pause voting on specific projects
- Minimum investment threshold adjustable
- Project status immutable once finalized

## Testing

### Unit Tests
```bash
# Run contract tests
clarinet test

# Check specific function
clarinet console
>>> (contract-call? .micro-investment-dao get-total-dao-funds)
```

### Integration Scenarios
- Multi-investor voting simulation
- Project approval/rejection flows
- Treasury management validation
- Emergency function testing

## Economics

### Tokenomics
- **Governance Token**: STX investment amount
- **Voting Power**: Proportional to investment
- **Treasury**: Pooled STX from all members
- **Project Funding**: Direct STX transfers

### Fee Structure
- **No platform fees**: Pure community funding
- **Gas costs**: Standard Stacks transaction fees
- **Investment minimum**: Configurable (default: 1 STX)

## Future Enhancements

### Planned Features
- **Dividend distribution** from successful projects
- **Reputation system** for project creators
- **Multi-token support** beyond STX
- **Advanced voting mechanisms** (quadratic voting)
- **Project milestones** with staged funding
- **DAO governance upgrades** through proposals

### Integration Opportunities
- **DeFi protocols** for yield generation
- **NFT rewards** for active participants
- **Cross-chain bridges** for multi-chain projects
- **Oracle integration** for project verification

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

##  License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

##  Support

- **Documentation**: [Clarity Language Reference](https://docs.stacks.co/clarity)
- **Community**: [Stacks Discord](https://discord.gg/stacks)
- **Issues**: [GitHub Issues](https://github.com/your-repo/micro-investment-dao/issues)

##  Acknowledgments

- Stacks Foundation for blockchain infrastructure
- Clarity language development team
- Community contributors and testers
