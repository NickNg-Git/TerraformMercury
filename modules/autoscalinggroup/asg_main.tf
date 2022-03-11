resource "aws_autoscaling_group" "autoscale_template" {
  name = var.name

  vpc_zone_identifier = var.vpc_zone_identifier
  
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size

  target_group_arns = var.target_group_arns

  launch_template {
    id      = var.launchtemplate_id
    version = "$Latest"
  }
}