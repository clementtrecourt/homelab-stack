# 📁 SRE Incident & Disaster Recovery Playbook

This document contains the operational runbook for disaster recovery of stateful services, followed by the postmortem of the simulated outage on June 2, 2026.

---

## 📖 Runbook: Restoring Uptime Kuma from Offsite Backup

**Service:** Uptime Kuma (Monitoring & Status Page)  
**Impact Level:** High (Loss of external visibility & SLA tracking)  
**Storage Type:** SQLite Database on Local-Path PV (backed up via Velero Node-Agent / Restic)

### Prerequisites
*   Velero CLI installed on the admin bastion.
*   Velero Backup Location status must be `Available` (verify with `velero backup-location get`).

### Recovery Procedure (Step-by-Step)

1.  **Verify the latest available backup:**
    ```bash
    velero backup get
    ```
    Identify the most recent stable backup (usually `uptime-kuma-daily-backup-<timestamp>` or `uptime-kuma-backup`).

2.  **Trigger the restore operation:**
    ```bash
    velero restore create --from-backup uptime-kuma-backup
    ```

3.  **Monitor the restoration progress:**
    ```bash
    velero restore get
    watch kubectl get pods -n uptime-kuma
    ```
    *The restore is complete when the restore status is `Completed` and the Uptime Kuma pod is `Running (1/1)`.*

4.  **Validate Service Restoration:**
    Access `https://status.clem-ops.org` from an external device in incognito mode. Verify that all historical monitors and status statistics are populated.

---

## 📝 Postmortem: Simulated Database & Namespace Corruption (2026-06-02)

**Owner/Author:** Clément Trecourt  
**Status:** Resolved  
**Duration of Outage:** ~10 minutes

### Executive Summary
On June 2, 2026, at 13:38 UTC, a simulated disaster recovery exercise was conducted. The entire `uptime-kuma` namespace, including its Persistent Volume containing the SQLite database, was completely deleted to simulate a total local disk failure. 

The service was successfully recovered using Velero and Cloudflare R2 offsite S3 storage. **RTO (Recovery Time Objective) achieved: ~2 minutes.** Zero data was lost (**RPO achieved: 0**).

### Timeline (UTC)
*   **13:37** - Verified active backup `uptime-kuma-backup` is successfully uploaded to Cloudflare R2.
*   **13:38** - **INCIDENT TRIGGERED:** Executed `kubectl delete ns uptime-kuma` (Simulating hardware crash).
*   **13:39** - Verified status page `https://status.clem-ops.org` is offline (Traefik returning 404).
*   **13:40** - **MITIGATION:** Initiated Velero restoration from R2: `velero restore create --from-backup uptime-kuma-backup`.
*   **13:41** - Velero recreated the namespace, PV, and redeployed the pod. Node-agent successfully restored the SQLite database.
*   **13:42** - **INCIDENT RESOLVED:** Pod status returned to `Running`. Verified status page is fully operational with all historical data intact.

### Lessons Learned & Action Items
*   **Sealed Secrets Collision (Resolved):** During the initial setup, a resource ownership conflict occurred between the Velero Helm chart and our SealedSecret for `velero-credentials`. *Action:* Resolved by renaming our custom SealedSecret to `velero-cloudflare-r2`, separating ownership and allowing seamless automated unsealing.
*   **Port 53 Conflict (Resolved):** The DNS LoadBalancer was blocked by local `systemd-resolved` services on the physical nodes. *Action:* Disabled `systemd-resolved` on all cluster nodes and configured CoreDNS as a `DaemonSet` on `hostNetwork: true` to ensure high availability.