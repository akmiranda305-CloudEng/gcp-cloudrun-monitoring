resource "google_monitoring_dashboard" "site" {
  dashboard_json = jsonencode({
    displayName = "Static site health"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Requests per second by response class"
            xyChart = {
              dataSets = [{
                plotType = "STACKED_BAR"
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.service_name}\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["metric.label.response_code_class"]
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          width  = 6
          height = 4
          widget = {
            title = "Request latency (95th percentile)"
            xyChart = {
              dataSets = [{
                plotType = "LINE"
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"run.googleapis.com/request_latencies\" resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.service_name}\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_PERCENTILE_95"
                      crossSeriesReducer = "REDUCE_MAX"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          yPos   = 4
          width  = 12
          height = 4
          widget = {
            title = "Uptime check success (fraction passing)"
            xyChart = {
              dataSets = [{
                plotType = "LINE"
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" resource.type=\"uptime_url\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_FRACTION_TRUE"
                      crossSeriesReducer = "REDUCE_MEAN"
                    }
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}
