# 🛣️ Crowdsourced Road Repairs Smart Contract

A decentralized platform for crowdsourcing road repair projects using the Stacks blockchain and Clarity smart contracts.

## 📋 Overview

This smart contract enables community members to propose road repair projects, accept contributions from the public, and coordinate with contractors to complete infrastructure improvements. The platform ensures transparency and accountability through blockchain-based project tracking.

## ✨ Features

- 🏗️ **Project Creation**: Community members can propose road repair projects with funding goals and deadlines
- 💰 **Crowdfunding**: Public contributors can fund projects with cryptocurrency
- 👷 **Contractor Management**: Project owners can assign contractors to execute repairs  
- 🔄 **Project States**: Comprehensive status tracking (Active, Funded, Completed, Canceled, Expired)
- 💸 **Refund System**: Automatic refunds for canceled or expired projects
- 📊 **Progress Tracking**: Real-time funding progress and statistics
- 🔒 **Access Control**: Role-based permissions for project management

## 🎯 Project States

| Status | Description |
|--------|-------------|
| `PROPOSED` | Initial project state (unused in current implementation) |
| `ACTIVE` | Project is accepting contributions |
| `FUNDED` | Project has reached its funding goal |
| `COMPLETED` | Road repairs have been finished |
| `CANCELED` | Project was canceled by owner |
| `EXPIRED` | Project deadline passed without full funding |

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://docs.stacks.co/docs/clarinet) installed
- Stacks wallet for testing

### Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd Crowdsourced-Road-Repairs
```

2. Verify the contract compiles:
```bash
clarinet check
```

3. Run tests (if available):
```bash
clarinet test
```

## 📖 Usage Guide

### Creating a Project

```clarity
(contract-call? .crowdsourced-road-repairs create-project 
  "Main Street Pothole Repair" 
  "Downtown Main Street" 
  u50000 
  u1000)
```

**Parameters:**
- `title`: Project name (max 64 bytes)
- `location`: Repair location (max 64 bytes)  
- `goal`: Funding target in microSTX
- `deadline`: Block height deadline

### Contributing to Projects

```clarity
(contract-call? .crowdsourced-road-repairs contribute u1 u10000)
```

**Parameters:**
- `project-id`: Target project ID
- `amount`: Contribution amount in microSTX

### Managing Projects

#### Assign a Contractor
```clarity
(contract-call? .crowdsourced-road-repairs update-contractor u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

#### Mark Project as Funded
```clarity
(contract-call? .crowdsourced-road-repairs mark-funded u1)
```

#### Complete a Project
```clarity
(contract-call? .crowdsourced-road-repairs mark-completed u1)
```

#### Cancel a Project
```clarity
(contract-call? .crowdsourced-road-repairs cancel-project u1)
```

### Getting Refunds

For canceled or expired projects:
```clarity
(contract-call? .crowdsourced-road-repairs refund u1)
```

## 🔍 Read-Only Functions

### Project Information
- `get-project`: Retrieve complete project details
- `get-status`: Get current project status
- `project-progress`: View funding progress
- `get-funding-percentage`: Calculate completion percentage
- `get-remaining-funds`: Amount still needed

### Contribution Data
- `get-contribution`: User's contribution to a project
- `has-contributed`: Check if user contributed
- `get-contributor-amount`: Get contribution amount
- `can-refund`: Check refund eligibility

### Platform Statistics
- `stats`: Overall platform metrics
- `get-next-project-id`: Next available project ID

### Status Checks
- `is-owner`: Check project ownership
- `is-active`: Check if project accepting contributions
- `is-funded`: Check if funding goal reached
- `is-completed`: Check if project finished
- `is-canceled`: Check if project canceled
- `is-expired`: Check if project expired
- `project-expired`: Detailed expiration check
- `project-funded`: Detailed funding check

## 🏗️ Contract Architecture

### Data Structures

#### Projects Map
```clarity
{
  id: uint,
  proposer: principal,
  title: (buff 64),
  location: (buff 64),
  goal: uint,
  pledged: uint,
  deadline: uint,
  status: uint,
  contractor: (optional principal),
  created-at: uint,
  updated-at: uint
}
```

#### Contributions Map
```clarity
{
  id: uint,
  sender: principal,
  amount: uint,
  refunded: bool,
  contributed-at: uint
}
```

### Global Variables
- `next-project-id`: Auto-incrementing project counter
- `total-projects`: Total number of projects created
- `total-pledged`: Total amount pledged across all projects
- `total-completed`: Number of completed projects
- `total-canceled`: Number of canceled projects
- `total-expired`: Number of expired projects

## ⚠️ Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| `u100` | `ERR-NOT-AUTHORIZED` | Insufficient permissions |
| `u101` | `ERR-INVALID-PARAMS` | Invalid function parameters |
| `u102` | `ERR-BAD-STATE` | Invalid project state for operation |
| `u103` | `ERR-NOT-FOUND` | Project or contribution not found |

## 🔐 Security Considerations

- ✅ **Access Control**: Only project owners can modify project details
- ✅ **State Validation**: Strict status checking prevents invalid transitions  
- ✅ **Deadline Enforcement**: Time-based constraints prevent abuse
- ✅ **Refund Protection**: Contributors can recover funds from failed projects
- ✅ **Double-spending Prevention**: Contribution tracking prevents duplicate refunds

## 🧪 Testing

The contract includes comprehensive validation and error handling. Test scenarios should cover:

- ✅ Project lifecycle (creation → funding → completion)
- ✅ Contribution and refund flows
- ✅ Access control enforcement
- ✅ State transition validation
- ✅ Edge cases and error conditions


## 📄 License

This project is licensed under the MIT License 
---

*Made with ❤️ for better roads and stronger communities* 🚗💨