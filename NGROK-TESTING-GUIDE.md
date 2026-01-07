# Testing with Ngrok Tunnel

This guide explains how to test the FHIR API using an ngrok tunnel to expose your local FHIR server to GitHub Actions CI/CD.

## Overview

The testing workflow uses your **locally running HAPI FHIR server** exposed through an **ngrok tunnel** instead of spinning up a separate FHIR server in GitHub Actions. This allows you to test against real data and configurations on your local machine.

## Prerequisites

- macOS with Homebrew (for automatic ngrok installation)
- Docker Desktop or Colima
- ngrok account (free tier works fine)
- Git repository with this FHIR API project

## Quick Start

### 1. Start FHIR Server with Ngrok Tunnel

The `start_demo.sh` script handles everything automatically:

```bash
./start_demo.sh
```

This script will:
1. Check if ngrok is installed (installs via Homebrew if missing)
2. Start Colima (if not running)
3. Launch the HAPI FHIR server in Docker
4. Wait for the FHIR server to be ready
5. Start an ngrok tunnel on port 8080
6. Save the ngrok public URL to `.ngrok-url.txt`
7. Display both local and public access URLs

### 2. Verify the Tunnel

After the script completes, you should see output like:

```
==========================================
🚀 FHIR Server Ready!
==========================================

Local Access:
  • FHIR Endpoint:    http://localhost:8080/fhir
  • Metadata:         http://localhost:8080/fhir/metadata

Public Access (ngrok tunnel):
  • FHIR Endpoint:    https://abc123.ngrok.io/fhir
  • Metadata:         https://abc123.ngrok.io/fhir/metadata
  • Ngrok Dashboard:  http://localhost:4040
```

Test both endpoints:

```bash
# Test local
curl http://localhost:8080/fhir/metadata

# Test public (ngrok)
curl https://abc123.ngrok.io/fhir/metadata
```

### 3. Commit the Ngrok URL for CI/CD

The ngrok URL is saved to `.ngrok-url.txt` and **must be committed** for GitHub Actions to use it:

```bash
git add .ngrok-url.txt
git commit -m "Update ngrok tunnel URL for CI/CD testing"
git push
```

### 4. Run GitHub Actions Workflow

Once the ngrok URL is committed, the GitHub Actions workflow will:
1. Check if `.ngrok-url.txt` exists in the repository
2. Verify the tunnel is accessible
3. Run the Insomnia API test collection against your local server
4. Generate test reports

You can trigger the workflow:
- Automatically on push/PR to `.insomnia/**` or `.spectral.yaml`
- Manually via workflow dispatch

## How It Works

### Start Script (start_demo.sh)

The script automates the entire setup:

```bash
#!/bin/bash

# 1. Install ngrok (if needed)
if ! command -v ngrok &> /dev/null; then
    brew install ngrok/ngrok/ngrok
fi

# 2. Start FHIR server
docker-compose up -d

# 3. Wait for FHIR server
until curl -sf http://localhost:8080/fhir/metadata > /dev/null; do
    sleep 2
done

# 4. Start ngrok tunnel
ngrok http 8080 --log=stdout > .ngrok.log 2>&1 &

# 5. Get and save ngrok URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"https://[^"]*' | head -1 | cut -d'"' -f4)
echo "$NGROK_URL/fhir" > .ngrok-url.txt
```

### GitHub Actions Workflow

The workflow (`api-governance.yml`) checks for the tunnel before running tests:

```yaml
- name: Check for ngrok tunnel
  run: |
    if [ -f ".ngrok-url.txt" ]; then
      NGROK_URL=$(cat .ngrok-url.txt)
      echo "Found tunnel: $NGROK_URL"
    else
      echo "❌ No tunnel found. Please run ./start_demo.sh"
      exit 1
    fi

- name: Verify tunnel is accessible
  run: |
    curl -sf --max-time 10 "$NGROK_URL/metadata"

- name: Run API Tests
  env:
    FHIR_BASE_URL: ${{ steps.check-tunnel.outputs.tunnel-url }}
  run: |
    inso run test -e "Base Environment" --ci
```

## Troubleshooting

### Ngrok URL Changes

**Problem:** The ngrok URL changes every time you restart the tunnel (unless you have a paid ngrok plan with reserved domains).

**Solution:** Update the committed `.ngrok-url.txt` file each time you restart:

```bash
./start_demo.sh
git add .ngrok-url.txt
git commit -m "Update ngrok URL"
git push
```

### Tunnel Not Accessible

**Problem:** GitHub Actions can't reach the ngrok URL.

**Possible causes:**
1. Your local machine is sleeping/offline
2. The FHIR server crashed
3. Ngrok tunnel expired (free tier has 2-hour limit)
4. Firewall blocking ngrok

**Solution:**
- Ensure your machine is awake and connected to internet
- Check ngrok dashboard: http://localhost:4040
- Check FHIR server logs: `docker-compose logs -f`
- Restart the tunnel: `./start_demo.sh`

### Tests Failing

**Problem:** Tests run but fail with errors.

**Check:**
1. Can you access the FHIR server locally? `curl http://localhost:8080/fhir/metadata`
2. Can you access through ngrok? `curl $(cat .ngrok-url.txt)/metadata`
3. Is the `.ngrok-url.txt` file committed and up-to-date?
4. Are there any data requirements for your tests? (e.g., pre-existing Patient resources)

### Ngrok Installation Issues

**Problem:** `brew install ngrok/ngrok/ngrok` fails.

**Manual installation:**
1. Download from https://ngrok.com/download
2. Extract and move to `/usr/local/bin/ngrok`
3. Make executable: `chmod +x /usr/local/bin/ngrok`
4. Verify: `ngrok version`

### Port Already in Use

**Problem:** Ngrok fails because port 8080 is already in use.

**Solution:**
```bash
# Find what's using port 8080
lsof -ti:8080

# Kill the process
kill -9 $(lsof -ti:8080)

# Or stop Docker containers
docker-compose down
```

## Ngrok Dashboard

Access the ngrok web dashboard at http://localhost:4040 to:
- See all active tunnels
- View real-time HTTP requests
- Inspect request/response details
- Replay requests
- Monitor tunnel status

## Stopping the Server

To stop everything:

```bash
# Stop ngrok tunnel
kill $(cat .ngrok.pid)

# Stop FHIR server
docker-compose down

# Stop Colima (optional)
colima stop
```

## Alternative: Ngrok Paid Features

If you have an ngrok paid plan, you can use **reserved domains** that don't change:

1. Reserve a domain in ngrok dashboard
2. Update `start_demo.sh` to use the reserved domain:
   ```bash
   ngrok http 8080 --domain=your-reserved-domain.ngrok.io
   ```
3. Commit the static URL once to `.ngrok-url.txt`
4. No need to update the file on each restart

## Security Considerations

### Public Access
- The ngrok tunnel makes your FHIR server publicly accessible
- Only run with test/demo data, never production data
- The tunnel is temporary (2-hour limit on free tier)
- Consider using ngrok authentication for added security

### Committed URLs
- The `.ngrok-url.txt` file is committed to git
- URLs are publicly visible in your repository
- URLs expire after 2 hours (free tier) so no long-term security risk
- Still, never use production data when exposing via ngrok

## CI/CD Best Practices

1. **Keep tunnel alive:** During CI/CD runs, ensure your local machine stays awake
2. **Update before runs:** Restart the tunnel and commit the new URL before triggering workflows
3. **Monitor runs:** Watch the ngrok dashboard during test execution
4. **Use GitHub Secrets:** For production, use GitHub repository secrets for sensitive URLs
5. **Document requirements:** Make it clear in PRs when local tunnel is needed

## Future Improvements

Potential enhancements:
1. Use GitHub self-hosted runners on the local machine (eliminates ngrok need)
2. Deploy FHIR server to cloud for persistent testing
3. Use ngrok API to auto-update `.ngrok-url.txt` in git
4. Implement webhook notifications when tunnel URL changes
5. Add ngrok authentication for additional security
