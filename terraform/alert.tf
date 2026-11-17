# Alert when the service returns any 5xx responses
resource "google_monitoring_alert_policy" "site_errors" {
  display_name = "Site errors: 5xx responses"
  combiner     = "OR"

  conditions {
    display_name = "5xx responses detected"

    condition_threshold {
      filter          = "metric.type=\"run.googleapis.com/request_count\" AND resource.type=\"cloud_run_revision\" AND resource.label.service_name=\"${var.service_name}\" AND metric.label.response_code_class=\"5xx\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.label.service_name"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    mime_type = "text/markdown"
    content   = "The Cloud Run service is returning 5xx errors. Check the most recent deployment first, and roll back if needed. Follow the runbook: https://github.com/akmiranda305-CloudEng/gcp-cloudrun-monitoring/blob/main/docs/runbook.md"
  }
}
