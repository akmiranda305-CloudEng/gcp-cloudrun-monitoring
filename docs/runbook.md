# Runbook: Static Site

**Owner:** Alex M. (GitHub: @akmiranda305-CloudEng)
**Last tested:** Rollback during game day on November 16, 2026; image lookup verified November 17, 2026

## Alert: Site errors: 5xx responses / Site down: uptime check failing

### Setup (run first in a new shell)

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=us-central1
export URL=$(gcloud run services describe static-site --region $REGION --format='value(status.url)')
```

If gcloud reports "no active account," run `gcloud auth login` and re-run the setup commands.

### 1. Confirm

1. Open Monitoring → Alerting → Incidents and note which alert fired.
2. Check the site's status code. Anything other than `200` confirms the problem:
   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" $URL
   ```
3. Open the Static site health dashboard and check for 5xx responses or a drop in the uptime line.

### 2. Check what changed

List recent revisions (newest first). Note when the newest one was created and whether it lines up with the first errors:

```bash
gcloud run revisions list --service static-site --region $REGION --limit 5
gcloud run services logs read static-site --region $REGION --limit 20
```

The rollback target is the newest revision created **before** the problem started. Save its image, replacing `REVISION_NAME` with that revision's name from the list:

```bash
export GOOD_IMAGE=$(gcloud run revisions describe REVISION_NAME --region $REGION --format='value(spec.containers[0].image)')
echo $GOOD_IMAGE
```

The image prints as a digest (`...@sha256:...`). That is expected and can be deployed as-is.

### 3. Mitigate

Roll back by redeploying the previous good image. Rollbacks use redeploy instead of pinning traffic, so automatic pipeline deploys keep working.

```bash
date -u
gcloud run deploy static-site --image "$GOOD_IMAGE" --region $REGION --project $PROJECT_ID
curl -s -o /dev/null -w "%{http_code}\n" $URL
```

Expected result: `200`. Record the time.

If it still doesn't return `200`, read the logs again and check that the service still allows public access.

### 4. Verify recovery

- The 5xx bar on the dashboard stops and the uptime line recovers.
- Alerting → Incidents: incidents close on their own once the condition clears (in the game day, within a few minutes).
- Monitoring → Services → Static site: open the SLO and note how much error budget the incident used.

### 5. Escalate / follow up

- Notify the service owner (see Owner above).
- Write a postmortem with timestamps within 3 days of the incident.
- Update this runbook with any steps that were missing or wrong.