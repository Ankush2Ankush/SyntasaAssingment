# Fix IAM Permissions for Elastic Beanstalk

## Problem
Your IAM user `deployment-user` doesn't have permissions to create IAM roles required by Elastic Beanstalk.

## Solution Options

### Option 1: Add IAM Permissions to Your User (Recommended)

You need to add IAM permissions to your `deployment-user`. 

#### Step 1: Go to AWS Console
1. Log in to AWS Console: https://console.aws.amazon.com/
2. Go to **IAM** → **Users**
3. Click on `deployment-user`

#### Step 2: Add Permissions
1. Click **Add permissions** → **Attach policies directly**
2. Search for and attach:
   - `PowerUserAccess` (gives most permissions except IAM)
   - OR `IAMFullAccess` (if you need full IAM access)
   - OR create a custom policy (see below)

#### Step 3: Custom Policy (More Secure)
If you prefer a custom policy with minimal permissions, create a new policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:PutRolePolicy",
                "iam:AttachRolePolicy",
                "iam:PassRole",
                "iam:GetRole",
                "iam:GetInstanceProfile",
                "iam:CreateInstanceProfile",
                "iam:AddRoleToInstanceProfile"
            ],
            "Resource": [
                "arn:aws:iam::*:role/aws-elasticbeanstalk-*",
                "arn:aws:iam::*:instance-profile/aws-elasticbeanstalk-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "s3:*",
                "cloudformation:*",
                "autoscaling:*",
                "logs:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### Option 2: Create Roles Manually (Alternative)

If you can't modify IAM permissions, create the roles manually:

#### Step 1: Create Service Role
1. Go to **IAM** → **Roles** → **Create role**
2. Select **AWS service** → **Elastic Beanstalk**
3. Attach policies:
   - `AWSElasticBeanstalkService`
   - `AWSElasticBeanstalkHealthEnhanced`
   - `AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy`
4. Role name: `aws-elasticbeanstalk-service-role`
5. Create role

#### Step 2: Create EC2 Instance Profile
1. Go to **IAM** → **Roles** → **Create role**
2. Select **AWS service** → **EC2**
3. Attach policies:
   - `AWSElasticBeanstalkWebTier`
   - `AWSElasticBeanstalkWorkerTier`
   - `AWSElasticBeanstalkMulticontainerDocker`
4. Role name: `aws-elasticbeanstalk-ec2-role`
5. Create role

#### Step 3: Create Instance Profile
1. Go to **IAM** → **Instance profiles** → **Create instance profile**
2. Name: `aws-elasticbeanstalk-ec2-role`
3. Add role: `aws-elasticbeanstalk-ec2-role`
4. Create

### Option 3: Use Existing Roles (If They Exist)

If the roles already exist, you can specify them:

```powershell
eb create nyc-taxi-api-env --service-role aws-elasticbeanstalk-service-role --instance-profile aws-elasticbeanstalk-ec2-role
```

## Quick Fix: Add PowerUserAccess

The fastest solution is to add `PowerUserAccess` to your user:

1. AWS Console → IAM → Users → `deployment-user`
2. **Add permissions** → **Attach policies directly**
3. Search: `PowerUserAccess`
4. Check the box and click **Add permissions**

**Note**: PowerUserAccess gives access to most AWS services but not IAM. If you still need IAM permissions, also attach `IAMFullAccess` (or use the custom policy above).

## Verify Permissions

After adding permissions, verify:

```powershell
aws iam get-user --user-name deployment-user
aws sts get-caller-identity
```

## Retry Deployment

Once permissions are fixed:

```powershell
cd backend
eb create nyc-taxi-api-env
```

## Security Note

For production, use the custom policy approach (Option 1, Step 3) to follow the principle of least privilege.


