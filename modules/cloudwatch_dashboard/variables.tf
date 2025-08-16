variable "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  type        = string
}

variable "widgets" {
  description = "List of widgets to include in the dashboard"
  type        = list(any)
}

variable "aws_region" {
  type        = string
  description = "Region for the metrics"
}
