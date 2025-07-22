# Decentralized Medical Records Interoperability System

A blockchain-based system for secure, patient-controlled medical record sharing across healthcare institutions.

## Overview

This system provides a decentralized approach to medical record management, ensuring patient privacy while enabling secure data sharing between healthcare providers. Built on the Stacks blockchain using Clarity smart contracts.

## Core Components

### 1. Patient Consent Management Contract (\`patient-consent.clar\`)
- Manages patient consent for data access
- Controls which healthcare providers can view records
- Tracks consent history and revocation
- Implements time-based access controls

### 2. Cross-Hospital Data Sharing Contract (\`cross-hospital-sharing.clar\`)
- Facilitates secure medical record transfers
- Validates provider credentials
- Maintains audit trails for all data access
- Implements data encryption key management

### 3. Emergency Access Protocol Contract (\`emergency-access.clar\`)
- Provides critical medical information during emergencies
- Bypasses normal consent requirements in life-threatening situations
- Logs all emergency access events
- Implements automatic consent restoration post-emergency

### 4. Prescription Drug Interaction Contract (\`prescription-interactions.clar\`)
- Prevents dangerous medication combinations
- Cross-references prescriptions across providers
- Maintains drug interaction database
- Alerts providers to potential conflicts

### 5. Medical Research Consent Contract (\`research-consent.clar\`)
- Manages patient consent for anonymized research
- Controls data usage for clinical studies
- Implements compensation mechanisms
- Tracks research participation history

## Key Features

- **Patient-Controlled Access**: Patients maintain full control over their medical data
- **Interoperability**: Seamless data sharing between healthcare institutions
- **Emergency Override**: Critical access during medical emergencies
- **Drug Safety**: Prevents dangerous prescription interactions
- **Research Participation**: Opt-in anonymized data sharing for medical research
- **Audit Trail**: Complete logging of all data access and modifications
- **Privacy Protection**: Zero-knowledge proofs for sensitive data verification

## Security Features

- Multi-signature requirements for sensitive operations
- Time-locked access controls
- Encrypted data storage references
- Provider credential verification
- Patient identity verification
- Automatic consent expiration

## Installation

\`\`\`bash
# Clone the repository
git clone <repository-url>
cd medical-records-system

# Install dependencies
npm install

# Run tests
npm test

# Deploy contracts (requires Clarinet)
clarinet deploy
\`\`\`

## Usage

### Patient Registration
1. Patient creates account and generates encryption keys
2. Initial medical data is encrypted and stored off-chain
3. Patient sets initial consent preferences

### Provider Access
1. Healthcare provider requests access to patient records
2. Patient approves/denies access request
3. Approved providers can access permitted data within time limits

### Emergency Situations
1. Emergency responders can trigger emergency access protocol
2. Critical medical information becomes immediately available
3. Patient is notified post-emergency of data access

### Prescription Management
1. Providers submit new prescriptions to interaction checker
2. System validates against existing medications
3. Warnings issued for potential dangerous interactions

### Research Participation
1. Patients opt-in to research programs
2. Anonymized data is made available to approved researchers
3. Patients can track research participation and compensation

## Testing

The system includes comprehensive tests covering:
- Contract deployment and initialization
- Patient consent management
- Provider access controls
- Emergency access protocols
- Drug interaction detection
- Research consent workflows

Run tests with:
\`\`\`bash
npm test
\`\`\`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Compliance

This system is designed to be compliant with:
- HIPAA (Health Insurance Portability and Accountability Act)
- GDPR (General Data Protection Regulation)
- State and federal medical privacy laws

**Note**: Legal review required before production deployment.
