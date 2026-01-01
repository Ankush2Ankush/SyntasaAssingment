# Elastic Beanstalk Initialization Instructions

## Quick Start

Run these commands from the `backend/` directory:

```powershell
cd backend
eb init
```

## Interactive Prompts Guide

When you run `eb init`, you'll be prompted with the following questions. Use these answers:

### 1. Select a region
```
(1) us-east-1 : US East (N. Virginia)
(2) us-west-1 : US West (N. California)
(3) us-west-2 : US West (Oregon)
...
```
**Answer**: Type `1` and press Enter (or select your preferred region)

### 2. Enter Application Name
```
Enter Application Name
(default is "Syntasa"): 
```
**Answer**: Type `nyc-taxi-api` and press Enter

### 3. Select a platform
```
Select a platform.
1) Docker
2) .NET Core on Linux
3) Go
4) Java
5) Node.js
6) PHP
7) Python
8) Ruby
...
```
**Answer**: Type `7` and press Enter (Python)

### 4. Select Platform Branch
```
Select a platform branch.
1) Python 3.11 running on 64bit Amazon Linux 2023
2) Python 3.12 running on 64bit Amazon Linux 2023
...
```
**Answer**: Type `1` and press Enter (Python 3.11)

### 5. Set up SSH
```
Do you want to set up SSH for your instances?
(Y/n):
```
**Answer**: Type `Y` and press Enter (Yes - recommended for troubleshooting)

### 6. Select a keypair
```
Select a keypair.
1) [ Create new KeyPair ]
2) [ Don't setup SSH ]
```
**Answer**: 
- If first time: Type `1` and press Enter (create new keypair)
- If you have existing keypair: Select it from the list

### 7. Keypair Name (if creating new)
```
Type a keypair name.
(Default is "eb-keypair"):
```
**Answer**: Press Enter to use default, or type a custom name

## After `eb init` Completes

You'll see:
```
Application nyc-taxi-api has been created.
```

## Next Steps

1. **Create Environment**:
   ```powershell
   eb create nyc-taxi-api-env
   ```

2. **Deploy**:
   ```powershell
   eb deploy
   ```

3. **Monitor**:
   ```powershell
   eb logs
   eb status
   ```

## Troubleshooting

If `eb init` fails:
- Verify AWS CLI is configured: `aws configure list`
- Check AWS credentials: `aws sts get-caller-identity`
- Ensure you have permissions for Elastic Beanstalk


