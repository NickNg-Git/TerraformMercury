output "mercury_app_lb_dns_name" {
    value = aws_lb.mercury_app_lb.dns_name
}

output "mercury_app_lb_arnsuffix" {
    value = aws_lb.mercury_app_lb.arn_suffix
}

output "mercury_app_lb_target_group_react_arn" {
    value = aws_lb_target_group.mercury_app_lb_target_group_react.arn
}

output "mercury_app_lb_target_group_api_arn" {
    value = aws_lb_target_group.mercury_app_lb_target_group_api.arn
}

output "mercury_app_lb_target_group_react_arnsuffix" {
    value = aws_lb_target_group.mercury_app_lb_target_group_react.arn_suffix
}

output "mercury_app_lb_target_group_api_arnsuffix" {
    value = aws_lb_target_group.mercury_app_lb_target_group_api.arn_suffix
}