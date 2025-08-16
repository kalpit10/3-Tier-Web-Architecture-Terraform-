// a widget is a visual component on a dashboard that displays specific information or provides quick access to AWS services and features. 
resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = var.widgets
  })
}

