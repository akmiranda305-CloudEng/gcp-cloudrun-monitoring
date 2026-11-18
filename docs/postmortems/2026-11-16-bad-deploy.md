# Postmortem: Simulated bad deployment (2026-11-16)

## Summary
This was a planned game-day exercise. I deployed a container image that returns HTTP 500 for every request, to confirm that the dashboard, alerts, and email notifications work and to practice a rollback. [Both alerts / The 5xx alert] fired within about 4 minutes, emails arrived for the alerts and the resolution, and I restored service by redeploying the previous image about 14 minutes after the bad deploy.

## Impact
From 09:16 to 09:30 Central (about 14 minutes), every request to the site returned HTTP 500. The availability SLO showed [confirm the label] -821.212%, far beyond its 99.5% target. The site has very little traffic, so a small number of failed requests (mostly uptime-check probes and my own test requests) was enough to exceed the entire budget.

## Timeline (Central Time)
- 09:16: bad revision deployed (T0)
- 09:20: first alert fired and first alert email received
- 09:25: cause identified (a new revision was created just before the first errors)
- 09:30: previous image redeployed; `curl` returned 200 
- 09:37: incidents closed and resolution email received 

Time to detect: about 4 minutes. Alert to diagnosis: 5 minutes. Diagnosis to mitigation: 5 minutes.

## Detection
[Which alert fired first, and whether the second followed.] Detection speed is limited by my own settings: a 5-minute uptime-check period and 5-minute aggregation windows. In a worse case, detection could take longer than the 4 minutes I saw.

## Root cause
The deployed container image returned HTTP 500 for every request. It was deployed manually, bypassing the pipeline, and the pipeline has no post-deploy check, so nothing verified that a new revision actually served traffic. In a real incident, the equivalent would be a release that starts up normally but fails when handling requests.

## Resolution
I identified the new revision as the only recent change and redeployed the previous good image. The service returned HTTP 200 at 09:30.

```bash
gcloud run deploy static-site --image "$GOOD_IMAGE" --region $REGION --project $PROJECT_ID
curl -s -o /dev/null -w "%{http_code}\n" $URL
```

## What went well
- Detection within 5 minutes
- Alert and resolution emails were both delivered
- The dashboard showed the 5xx spike clearly
- Rollback was a single command

## What could be better
- The runbook depended on shell variables that wouldn't exist in a real incident (fixed: the runbook now has a setup section and a way to find the previous image)
- Diagnosis took 5 minutes because I had to look up which revision was the last good one
- The SLO is too noisy at this traffic level

## Action items
- [ ] Shorten the uptime-check period to 1 minute to cut detection time
- [ ] Link the runbook from both alert policies' documentation text
- [ ] Add an absolute-count alert, or lengthen the SLO window, since ratios are unreliable at this traffic level
