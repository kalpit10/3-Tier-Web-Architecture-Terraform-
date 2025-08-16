locals {
  ec2_dashboard_widgets = flatten([
    for id in data.aws_instances.app_ec2.ids : [
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          title  = "CPU Usage - ${id}"
          view   = "timeSeries"
          region = "us-east-1"
          metrics = [
            ["CWAgent", "cpu_usage_idle", "InstanceId", id]
          ]
          period = 60 // Update every 60 seconds
          stat   = "Average" // Pull out average of CPU utilization
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 6,
        width  = 12,
        height = 6,
        properties = {
          title  = "Memory Usage (%) - ${id}"
          view   = "timeSeries"
          region = "us-east-1"
          metrics = [
            ["CWAgent", "mem_used_percent", "InstanceId", id]
          ]
          period = 60
          stat   = "Average"
        }
      }
    ]
  ])
}
