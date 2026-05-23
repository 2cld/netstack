[edit](https://github.com/2cld/netstack/edit/master/docs/ops/monitor/performance-baseline-pattern.md) or [./](./)

# Performance Baseline Pattern

Collect and log performance statistics over time so you know what "stable" looks like. Without a baseline, you can't tell if something is degrading — you only notice when it breaks.

## Why

- "It feels slow" is not actionable. "Disk latency went from 2ms to 45ms" is.
- Baselines let you detect drift before it becomes an outage.
- Historical data answers "was it always like this?" after a change.
- Capacity planning: know when you'll run out of disk/RAM/CPU before it happens.

## What to Measure

### Per Node (collect daily)

| Metric | Command (Linux) | Command (Windows) | Why |
|--------|-----------------|-------------------|-----|
| **Disk free %** | `df -h /` | `Get-PSDrive C,D` | Predict when full |
| **Disk I/O latency** | `iostat -x 1 3` | `Get-Counter '\PhysicalDisk(*)\Avg. Disk sec/Read'` | Detect degrading storage |
| **RAM used/free** | `free -m` | `Get-CimInstance Win32_OperatingSystem` | Detect memory pressure |
| **CPU load avg** | `uptime` (load avg) | `Get-Counter '\Processor(_Total)\% Processor Time'` | Detect sustained load |
| **Uptime** | `uptime` | `(Get-CimInstance Win32_OperatingSystem).LastBootUpTime` | Detect unexpected reboots |
| **Process count** | `ps aux \| wc -l` | `(Get-Process).Count` | Detect runaway processes |
| **Top RAM consumers** | `ps aux --sort=-%mem \| head -5` | `Get-Process \| Sort WS -Desc \| Select -First 5` | Know what's eating RAM |
| **Network latency** | `ping -c3 10.147.17.x` | `Test-Connection 10.147.17.x -Count 3` | Detect overlay degradation |
| **ZeroTier peer status** | `zerotier-cli peers` | `zerotier-cli peers` | DIRECT vs RELAY |

### Per Service (collect daily)

| Metric | How | Why |
|--------|-----|-----|
| **HTTP response time** | `curl -o /dev/null -s -w '%{time_total}' URL` | Detect service slowdown |
| **Docker container restarts** | `docker ps --format '{{.Names}} {{.Status}}'` | Detect crash loops |
| **Backup age** | Check `.backup-state` timestamp | Detect stale backups |
| **Disk growth rate** | Compare today's free vs yesterday's | Predict capacity issues |

## Collection Script Pattern

```bash
#!/bin/bash
# perf-baseline.sh — collect daily performance snapshot
# Run via cron: 0 6 * * * bash perf-baseline.sh >> /var/log/perf-baseline.log

DATE=$(date +%Y-%m-%d)
HOST=$(hostname)

echo "=== ${HOST} ${DATE} ==="

# Disk
echo "DISK:"
df -h / | awk 'NR==2 {print "  / " $3 " used, " $4 " free (" $5 ")"}'

# RAM
echo "RAM:"
free -m | awk '/Mem:/ {printf "  %dMB used / %dMB total (%d%%)\n", $3, $2, $3*100/$2}'

# CPU load
echo "CPU:"
uptime | awk -F'load average:' '{print "  load:" $2}'

# Uptime
echo "UPTIME:"
uptime -p

# Top 3 RAM
echo "TOP_RAM:"
ps aux --sort=-%mem | awk 'NR>1 && NR<=4 {printf "  %s %.0fMB\n", $11, $6/1024}'

# Network (ping federation nodes)
echo "NETWORK:"
for ip in 10.147.17.219 10.147.17.218 10.147.17.94 10.147.17.165; do
  ms=$(ping -c1 -W2 $ip 2>/dev/null | grep -oP 'time=\K[0-9.]+' || echo "DOWN")
  echo "  ${ip}: ${ms}ms"
done

echo "=== END ==="
echo ""
```

### Windows Version (PowerShell)

```powershell
# perf-baseline.ps1 — collect daily performance snapshot
$date = Get-Date -Format "yyyy-MM-dd"
$host_name = hostname

Write-Output "=== $host_name $date ==="

# Disk
Write-Output "DISK:"
Get-PSDrive C,D -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Output ("  {0}: {1:N0}GB used, {2:N0}GB free" -f $_.Name, ($_.Used/1GB), ($_.Free/1GB))
}

# RAM
Write-Output "RAM:"
$os = Get-CimInstance Win32_OperatingSystem
$usedMB = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1024)
$totalMB = [math]::Round($os.TotalVisibleMemorySize / 1024)
$pct = [math]::Round($usedMB * 100 / $totalMB)
Write-Output "  ${usedMB}MB used / ${totalMB}MB total (${pct}%)"

# CPU
Write-Output "CPU:"
$cpu = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 1).CounterSamples.CookedValue
Write-Output ("  {0:N0}% utilization" -f $cpu)

# Uptime
Write-Output "UPTIME:"
$boot = $os.LastBootUpTime
$up = (Get-Date) - $boot
Write-Output ("  {0} days, {1} hours" -f $up.Days, $up.Hours)

# Top 3 RAM
Write-Output "TOP_RAM:"
Get-Process | Sort WorkingSet64 -Descending | Select -First 3 | ForEach-Object {
    Write-Output ("  {0} {1:N0}MB" -f $_.ProcessName, ($_.WorkingSet64/1MB))
}

# Network
Write-Output "NETWORK:"
@("10.147.17.219","10.147.17.218","10.147.17.176","10.147.17.94") | ForEach-Object {
    $result = Test-Connection $_ -Count 1 -TimeoutSeconds 2 -ErrorAction SilentlyContinue
    if ($result) { Write-Output "  ${_}: $($result.Latency)ms" }
    else { Write-Output "  ${_}: DOWN" }
}

Write-Output "=== END ==="
```

## Log Format

Append to a rolling log file. One entry per day per node.

```
/var/log/perf-baseline.log        (Linux)
C:\logs\perf-baseline.log         (Windows)
```

Keep 90 days of history. Rotate monthly:
```bash
# Linux cron (1st of month)
0 0 1 * * mv /var/log/perf-baseline.log /var/log/perf-baseline-$(date +%Y%m).log
```

## Reading the Baseline

After 7+ days of collection, you have a baseline. Look for:

| Pattern | Meaning | Action |
|---------|---------|--------|
| Disk free dropping 1-2% daily | Normal growth | Plan capacity (when will it hit 90%?) |
| Disk free dropped 20% overnight | Something dumped data | Investigate immediately |
| RAM usage creeping up over weeks | Memory leak or accumulation | Identify process, restart or fix |
| Network latency jumped from 2ms to 50ms | ZeroTier relay instead of direct | Check `zerotier-cli peers`, restart ZT |
| CPU load avg > core count | Sustained overload | Identify top process, consider migration |
| Uptime reset unexpectedly | Crash or forced reboot | Check event logs |

## Alerting Thresholds (suggested)

| Metric | Warning | Critical |
|--------|:-------:|:--------:|
| Disk free | < 20% | < 10% |
| RAM used | > 85% | > 95% |
| CPU load (sustained) | > 80% for 5 min | > 95% for 5 min |
| Network latency (ZT) | > 50ms | > 200ms or DOWN |
| Backup age | > 48 hours | > 7 days |
| Uptime | < 1 day (unexpected) | — |

## Integration with Morning Check-in

```javascript
// In morning-checkin.js, add:
// 1. Read latest perf-baseline.log entry
// 2. Compare against thresholds
// 3. Flag anything outside normal range
// 4. Include in daily report
```

## Evolution Path

This pattern starts simple (daily log file) and can evolve:

1. **Now:** Bash/PowerShell scripts → log files → manual review
2. **Next:** morning-checkin.js reads logs → flags anomalies automatically
3. **Later:** Gatus or similar lightweight dashboard (if visual monitoring needed)
4. **Future:** Grafana + Loki (if federation grows beyond 3-5 nodes)

Start with #1. Don't over-engineer. The log file IS the database for now.

## Related

- [monitoring-pattern.md](./monitoring-pattern.md) — service health checks
- [process-audit-pattern.md](./process-audit-pattern.md) — identifying resource hogs
- [request-lifecycle.md](./request-lifecycle.md) — tracking requests to completion
- [../deployments/federation-setup-guide.md](../deployments/federation-setup-guide.md) — what to monitor per site
