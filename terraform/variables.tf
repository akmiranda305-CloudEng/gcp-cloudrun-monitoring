variable "project_id" {
  description = "Your GCP project ID"
  type        = string
}

variable "region" {
  description = "Region where the Cloud Run service lives"
  type        = string
  default     = "us-central1"
}

variable "service_name" {
  description = "Name of the Cloud Run service to monitor"
  type        = string
  default     = "static-site"
}

variable "alert_email" {
  description = "Email address that receives alerts"
  type        = string
}
