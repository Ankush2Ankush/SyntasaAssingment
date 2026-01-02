# Check deployment status and logs
# Run this to diagnose why deployment is stuck

Write-Host "`n=== Checking Deployment Status ===" -ForegroundColor Cyan
Write-Host ""

# Check current status
Write-Host "1. Current Environment Status:" -ForegroundColor Yellow
eb status
Write-Host ""

# Check recent events
Write-Host "2. Recent Events (last 20):" -ForegroundColor Yellow
eb events --follow
Write-Host ""

# Check if we should wait or abort
Write-Host "3. Recommendations:" -ForegroundColor Yellow
Write-Host "   - If 'Updating' for < 15 minutes: Wait, deployment may still be running" -ForegroundColor Gray
Write-Host "   - If 'Updating' for > 20 minutes: May be stuck, consider aborting" -ForegroundColor Gray
Write-Host "   - If errors in events: Check logs for details" -ForegroundColor Gray
Write-Host ""

Write-Host "To view full logs:" -ForegroundColor Cyan
Write-Host "  eb logs --all" -ForegroundColor White
Write-Host ""

Write-Host "To abort deployment (if stuck):" -ForegroundColor Cyan
Write-Host "  eb abort" -ForegroundColor White
Write-Host ""

Write-Host "To monitor in real-time:" -ForegroundColor Cyan
Write-Host "  eb events --follow" -ForegroundColor White
Write-Host ""


