resource "aws_launch_template" "base_launch_template" {
  name = "${var.template_name}"

  image_id = "${var.ami_id}"
  instance_type = "${var.instance_type}"

  key_name = "${var.key_name}"
  vpc_security_group_ids = var.security_group_ids

  user_data = base64encode(var.userdata_content)

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.instance_name}"
    }
  }
}