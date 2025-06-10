# Transparent Government Grant Distribution (Public Sector / Governance)
A blockchain-based solution for transparent and accountable government grant distribution.

## 🎯 Purpose

This smart contract enables:
- 📝 Grant applications submission
- ✅ Transparent approval process
- 🎯 Milestone-based fund distribution
- 📊 Public tracking and auditing

## 🔧 Core Features

1. Grant Application
2. Government Approval
3. Milestone Management
4. Progress Tracking
5. Public Verification

## 📚 Usage Guide

### For Grant Applicants

1. Submit grant application:
```clarity
(contract-call? .grant-system apply-for-grant u1000 "Community Development Project")
```

2. Add milestones after approval:
```clarity
(contract-call? .grant-system add-milestone u1 "Phase 1: Planning" u250)
```

### For Government Officials

1. Initialize government address:
```clarity
(contract-call? .grant-system initialize-government tx-sender)
```

2. Approve grants:
```clarity
(contract-call? .grant-system approve-grant u1)
```

3. Complete milestones:
```clarity
(contract-call? .grant-system complete-milestone u1 u1)
```

### For Public Auditing

1. View grant details:
```clarity
(contract-call? .grant-system get-grant-details u1)
```

2. Check milestone status:
```clarity
(contract-call? .grant-system get-milestone-details u1 u1)
```

## 🔒 Security

- Only authorized government officials can approve grants
- Milestone-based fund distribution ensures accountability
- All transactions are permanently recorded on the blockchain

## 🤝 Contributing

Feel free to submit issues and enhancement requests!
