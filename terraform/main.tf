# Look up the Cloud Run service from Project 1 instead of hard-coding its URL
data "google_cloud_run_v2_service" "site" {
  name     = var.service_name
  location = var.region
}

locals {
  site_host = trimprefix(data.google_cloud_run_v2_service.site.uri, "https://")
}

# Where alerts get sent
resource "google_monitoring_notification_channel" "email" {
  display_name = "Portfolio alerts (email)"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

# Probes the site from several locations on a schedule
resource "google_monitoring_uptime_check_config" "site" {
  display_name = "static-site-https"
  timeout      = "10s"
  period       = "300s"

  http_check {
    path         = "/"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = local.site_host
    }
  }
}

# Alert when the uptime check fails from more than one location
resource "google_monitoring_alert_policy" "site_down" {
  display_name = "Site down: uptime check failing"
  combiner     = "OR"

  conditions {
    display_name = "Uptime check failing"

    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.label.check_id=\"${google_monitoring_uptime_check_config.site.uptime_check_id}\" AND resource.type=\"uptime_url\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1
      duration        = "60s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.*"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    mime_type = "text/markdown"
    content   = "The public site is failing its uptime check from multiple locations. Follow the runbook: https://github.com/akmiranda305-CloudEng/gcp-cloudrun-monitoring/blob/main/docs/runbook.md"
  }
}