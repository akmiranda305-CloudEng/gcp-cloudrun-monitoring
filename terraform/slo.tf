resource "google_monitoring_custom_service" "site" {
  service_id   = "static-site"
  display_name = "Static site"
}

resource "google_monitoring_slo" "availability" {
  service             = google_monitoring_custom_service.site.service_id
  slo_id              = "availability-995"
  display_name        = "99.5% of requests succeed (28 days)"
  goal                = 0.995
  rolling_period_days = 28

  request_based_sli {
    good_total_ratio {
      bad_service_filter   = "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.service_name}\" metric.label.response_code_class=\"5xx\""
      total_service_filter = "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.service_name}\""
    }
  }
}
