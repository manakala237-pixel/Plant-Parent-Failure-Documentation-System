# Plant Parent Failure Documentation System

## Overview

The Plant Parent Failure Documentation System is a blockchain-based smart contract platform designed to memorialize the universal transition from ambitious urban jungle dreams to the harsh reality of becoming a serial plant killer. This system provides a humorous yet practical approach to tracking plant care failures and the inevitable cycle of good intentions gone wrong.

## Project Description

Memorializes the transition from 'I'm going to create an urban jungle' to 'even my succulents are judging me'. This system captures the emotional journey every plant parent experiences, from the optimistic purchase of that first fiddle leaf fig to the acceptance that even air plants aren't safe in your care.

## Smart Contracts

### 1. Plant Identification App Usage vs Mortality Rate Contract
**Purpose**: Correlates the frequency of 'Is my plant dying?' searches with inevitable plant obituary writing.

This contract tracks:
- Search frequency patterns
- Plant identification attempts
- Mortality correlation data
- Emergency plant care queries
- Final plant status updates

### 2. Watering Schedule Good Intentions Tracker Contract
**Purpose**: Documents the lifecycle of elaborate plant care spreadsheets from creation to complete abandonment.

This contract manages:
- Watering schedule creation timestamps
- Intention commitment levels
- Schedule abandonment patterns
- Guilt tracking metrics
- Recovery attempt documentation

## Features

### Core Functionality
- **Failure Documentation**: Comprehensive tracking of plant care failures
- **Intention Tracking**: Monitor the lifecycle of plant care good intentions
- **Mortality Correlation**: Statistical analysis of care attempts vs plant survival
- **Guilt Management**: Emotional state tracking throughout the plant parenting journey
- **Recovery Attempts**: Documentation of renewed plant care commitments

### Technical Specifications
- Built with Clarity smart contract language
- Deployed on Stacks blockchain
- Gas-optimized operations
- Secure data storage
- Event logging for all major actions

## Getting Started

### Prerequisites
- Clarinet CLI tool
- Node.js and npm
- Git

### Installation
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd Plant-Parent-Failure-Documentation-System
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Check contract syntax:
   ```bash
   clarinet check
   ```

### Development Workflow
1. Create new contracts: `clarinet contract new <contract-name>`
2. Edit contracts in the `contracts/` directory
3. Test contracts: `clarinet test`
4. Deploy: `clarinet deploy`

## Project Structure
```
Plant-Parent-Failure-Documentation-System/
├── contracts/
│   ├── plant-identification-app-usage-vs-mortality-rate.clar
│   └── watering-schedule-good-intentions-tracker.clar
├── tests/
├── settings/
├── Clarinet.toml
├── package.json
└── README.md
```

## Usage Examples

### Recording Plant Care Failure
```clarity
;; Record a new plant care failure
(contract-call? .plant-identification-app-usage-vs-mortality-rate record-plant-death 
  "fiddle-leaf-fig" 
  "overwatering-despite-research")
```

### Tracking Watering Schedule Abandonment
```clarity
;; Document watering schedule abandonment
(contract-call? .watering-schedule-good-intentions-tracker abandon-schedule 
  schedule-id 
  "forgot-after-two-weeks")
```

## Contributing

We welcome contributions from fellow plant killers and those who've successfully kept a plant alive for more than a month (we're still skeptical of you). 

### Development Guidelines
1. Follow Clarity best practices
2. Include comprehensive tests
3. Document all functions
4. Maintain the humorous tone while ensuring functionality

## Testing

Run the test suite:
```bash
clarinet test
```

Check contract syntax:
```bash
clarinet check
```

## License

This project is open source and available under the MIT License. Because like your plants, code should be free to die in the wild.

## Support

If you're experiencing issues with this system, consider that it might be working perfectly - after all, documenting failure is its primary purpose.

For technical support, please open an issue on GitHub. For emotional support regarding your latest plant casualty, we recommend therapy.

## Acknowledgments

- To all the plants that gave their lives in the pursuit of our green thumb dreams
- To the plant identification apps that tried their best
- To the elaborate spreadsheets that collected digital dust
- To the succulents that somehow still managed to die

Remember: Every master plant parent was once a serial plant killer. This system just helps you document the journey with dignity and a sense of humor.