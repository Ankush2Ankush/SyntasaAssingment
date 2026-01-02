# Update Database Configuration for Elastic Beanstalk

## Quick Fix: Update DATABASE_URL in AWS Console

Since you've already set up the new database, you need to update the `DATABASE_URL` environment variable in AWS Elastic Beanstalk Console.

### Step 1: Navigate to Environment Configuration

1. Go to AWS Console: https://console.aws.amazon.com/
2. Make sure you're in **us-east-1** region
3. Search for **"Elastic Beanstalk"**
4. Click on your application: **nyc-taxi-api**
5. Click on your environment: **nyc-taxi-api-env**
6. Click on **"Configuration"** in the left sidebar
7. Scroll down and click **"Edit"** under **"Software"** section

### Step 2: Update DATABASE_URL Environment Variable

1. Scroll to **"Environment properties"** section
2. Find `DATABASE_URL` in the list (or add it if it doesn't exist)
3. Update the value with your new database connection string:

**For PostgreSQL/RDS:**
```
postgresql://username:password@your-rds-endpoint.region.rds.amazonaws.com:5432/database_name
```

**Example:**
```
postgresql://postgres:mypassword@nyc-taxi-db.abc123.us-east-1.rds.amazonaws.com:5432/nyc_taxi_db
```

**For SQLite (if using local file):**
```
sqlite:///./nyc_taxi.db
```

4. Click **"Apply"** at the bottom
5. Wait for the environment to update (5-10 minutes)

### Step 3: Verify the Update

1. After the update completes, check the **"Events"** tab
2. Look for **"Environment update completed successfully"**
3. Check the **"Health"** status - it should return to **"Ok"** (green)

### Step 4: Test the Connection

Once the environment is healthy, test your API endpoints to verify the database connection is working.

---

## Alternative: Update via EB CLI

If you prefer using command line:

```powershell
cd backend
eb setenv DATABASE_URL="postgresql://username:password@your-rds-endpoint:5432/database_name"
```

Replace the connection string with your actual database credentials.

---

## Important Notes

1. **Security**: Never commit database passwords to git. Always use AWS Console or environment variables.

2. **Connection String Format**:
   - PostgreSQL: `postgresql://username:password@host:port/database`
   - SQLite: `sqlite:///./filename.db`

3. **RDS Endpoint**: You can find your RDS endpoint in:
   - AWS Console → RDS → Databases → Your Database → Connectivity & security → Endpoint

4. **After Update**: The application will automatically restart and use the new database connection.

5. **If Health Check Fails**: 
   - Check the Logs tab for connection errors
   - Verify your RDS security group allows connections from Elastic Beanstalk
   - Verify the database credentials are correct

---

## Troubleshooting

### Health Check Still Failing

1. **Check Logs**: Go to Logs tab → Request Logs → Last 100 Lines
2. Look for database connection errors
3. Common issues:
   - Wrong password
   - RDS security group not allowing EB instances
   - Database doesn't exist
   - Network connectivity issues

### RDS Security Group Configuration

Make sure your RDS security group allows inbound connections from your Elastic Beanstalk environment:

1. Go to RDS → Your Database → Connectivity & security
2. Click on the Security group
3. Edit inbound rules
4. Add rule:
   - Type: PostgreSQL
   - Port: 5432
   - Source: Your Elastic Beanstalk security group (or 0.0.0.0/0 for testing)

---

## Current Configuration

The `.ebextensions/01_python.config` file has been updated to allow DATABASE_URL to be set via AWS Console environment variables. The configuration file no longer hardcodes the database URL, giving you flexibility to update it without redeploying code.

