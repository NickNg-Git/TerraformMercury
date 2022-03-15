terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=3.47.0"
    }
  }
}

resource "aws_key_pair" "mercury_keypair" {
  key_name   = "MercuryProductionKeyPPK"
  public_key = file("./MercuryProductionKey_Public")
}

resource "aws_kms_key" "mercury_kms_db" {
  description             = "Mercury Production DB - KMS Key"
  deletion_window_in_days = 10
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true
  tags = {
    Name = "MercuryProductionDB_KMSKey"
  }
}

resource "aws_kms_alias" "mercury_kms_db_alias" {
  name          = "alias/MercuryProduction_DBEncryptionKey"
  target_key_id = aws_kms_key.mercury_kms_db.key_id
}

## AWS Credentials - stored in terraform.tfvars ##
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

## Provision Network Resources ##
module "network" {
  source = "./modules/network"
}

## Create Security Groups ##
module "securitygroup" {
  source                        = "./modules/securitygroup"
  vpc_id                        = module.network.vpc_id
  private_subnet_app_cidr_list  = module.network.private_subnets_app_cidr_list
}

## Create Load Balancer ##
module "loadbalancer" {
  source          = "./modules/loadbalancer"
  security_groups = ["${module.securitygroup.sg_applb_id}"]
  subnet_groups   = ["${module.network.public_subnet_az1_id}", "${module.network.public_subnet_az2_id}"]
  vpc_id          = module.network.vpc_id
}

## Create Database ##
module "database" {
  source = "./modules/database"

  db_subnet_group_name    = "mercury-production-db_subnetgroup"
  db_subnet_group_tagname = "Mercury Productionter DB Subnet Group"
  subnet_groups           = ["${module.network.private_subnet_db_az1_id}", "${module.network.private_subnet_db_az2_id}"]

  db_name       = "smartbankdb"
  db_identifier = "mercury-smartbankdb"

  security_groups     = ["${module.securitygroup.sg_db_id}", "${module.securitygroup.sg_bastionguest_id}"]
  multi_az            = true
  publicly_accessible = false

  kms_key_arn = aws_kms_key.mercury_kms_db.arn
}

## Load User Data File for Mailman ##
data "http" "raw_userdata_mailman" {
  url = "https://raw.githubusercontent.com/JeremyKuah/SmartBank_UserData/main/userdata_mailman.sh"
}
data "template_file" "userdata_mailman" {
  template = data.http.raw_userdata_mailman.body
}

## Create Mailman EC2 Instance ##
resource "aws_instance" "mercury_prod_mailman_instance" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  user_data              = base64encode(data.template_file.userdata_mailman.rendered)
  key_name               = aws_key_pair.mercury_keypair.key_name
  vpc_security_group_ids = ["${module.securitygroup.sg_mailman_id}", "${module.securitygroup.sg_bastionguest_id}"]
  subnet_id              = module.network.private_subnet_apps_az3_id
  tags = {
    Name = "Mercury Production - Mailman App"
  }
}

## Load User Data File for API and React ##
data "http" "raw_userdata_api" {
  url = "https://raw.githubusercontent.com/JeremyKuah/SmartBank_UserData/main/userdata_api_cloudwatch.sh"
}
data "template_file" "userdata_api" {
  template = data.http.raw_userdata_api.body
  vars = {
    db_endpoint      = "${module.database.db_endpoint}"
    db_name          = "${module.database.db_name}"
    mailman_endpoint = "${aws_instance.mercury_prod_mailman_instance.private_ip}"
  }
}

data "http" "raw_userdata_react" {
  url = "https://raw.githubusercontent.com/JeremyKuah/SmartBank_UserData/main/userdata_react.sh"
}
data "template_file" "userdata_react" {
  template = data.http.raw_userdata_react.body
  vars = {
    lb_dns_name = "${module.loadbalancer.mercury_app_lb_dns_name}"
  }
}

## Create IAM Role Instance for Cloud Watch Agent ##
data "aws_iam_role" "mercury_prod_cloudwatchagentserverrole" {
  name = "Mercury_CloudWatchAgentServerRole"
}
resource "aws_iam_instance_profile" "mercury_prod_launchtemplate_instanceprofile" {
  name = "MercuryProduction_LaunchTemplateIamInstanceProfile"
  role = data.aws_iam_role.mercury_prod_cloudwatchagentserverrole.name
}

## Create Launch Template (API) ##
module "launchtemplate_api" {
  source               = "./modules/launchtemplate"
  ami_id               = var.ami_id
  template_name        = "MercuryProduction-API-Template"
  instance_type        = "t2.micro"
  userdata_content     = data.template_file.userdata_api.rendered
  key_name             = aws_key_pair.mercury_keypair.key_name
  instance_profile_arn = resource.aws_iam_instance_profile.mercury_prod_launchtemplate_instanceprofile.arn
  instance_name        = "Mercury Production - API App"
  security_group_ids   = ["${module.securitygroup.sg_apiapp_id}", "${module.securitygroup.sg_bastionguest_id}"]
}

## Create Launch Template (React) ##
module "launchtemplate_react" {
  source               = "./modules/launchtemplate"
  ami_id               = var.ami_id
  template_name        = "MercuryProduction-React-Template"
  instance_type        = "t2.micro"
  userdata_content     = data.template_file.userdata_react.rendered
  key_name             = aws_key_pair.mercury_keypair.key_name
  instance_profile_arn = resource.aws_iam_instance_profile.mercury_prod_launchtemplate_instanceprofile.arn
  instance_name        = "Mercury Production - React App"
  security_group_ids   = ["${module.securitygroup.sg_reactapp_id}", "${module.securitygroup.sg_bastionguest_id}"]
}

## Create Auto Scaling Group ##
module "autoscalinggroup_api" {
  source              = "./modules/autoscalinggroup"
  name                = "MercuryProd-ASG-API"
  vpc_zone_identifier = ["${module.network.private_subnet_apps_az1_id}", "${module.network.private_subnet_apps_az2_id}"]
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1
  launchtemplate_id   = module.launchtemplate_api.launchtemplate_id
  target_group_arns   = [module.loadbalancer.mercury_app_lb_target_group_api_arn]
}
module "autoscalinggroup_react" {
  source              = "./modules/autoscalinggroup"
  name                = "MercuryProd-ASG-React"
  vpc_zone_identifier = ["${module.network.private_subnet_apps_az1_id}", "${module.network.private_subnet_apps_az2_id}"]
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1
  launchtemplate_id   = module.launchtemplate_react.launchtemplate_id
  target_group_arns   = [module.loadbalancer.mercury_app_lb_target_group_react_arn]
}

## Create Auto Scaling Policy ##
resource "aws_autoscaling_policy" "api_autoscalingpolicy" {
  name                   = "MercuryProd-ASG-API-AutoScalePolicy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = "${module.autoscalinggroup_api.autoscalegroup_name}"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${module.loadbalancer.mercury_app_lb_arnsuffix}/${module.loadbalancer.mercury_app_lb_target_group_api_arnsuffix}"
    }
    target_value     = 5
    disable_scale_in = false
  }
}
resource "aws_autoscaling_policy" "react_autoscalingpolicy" {
  name                   = "MercuryProd-ASG-React-AutoScalePolicy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = "${module.autoscalinggroup_react.autoscalegroup_name}"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${module.loadbalancer.mercury_app_lb_arnsuffix}/${module.loadbalancer.mercury_app_lb_target_group_react_arnsuffix}"
    }
    target_value     = 5
    disable_scale_in = false
  }
}

## Create Bastion Host ##
resource "aws_instance" "mercury_bastion_host" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = module.network.public_subnet_az3_id
  vpc_security_group_ids      = ["${module.securitygroup.sg_bastionhost_id}"]
  key_name                    = aws_key_pair.mercury_keypair.key_name

  tags = {
    Name = "Mercury Production Bastion Host"
  }
}

## Create Cloudwatch ##
resource "aws_cloudwatch_dashboard" "mercury_prod_cloudwatch_dashboard" {
  dashboard_name = "MercuryProduction-Dashboard"

  dashboard_body = <<EOF
          {
            "widgets": [
              {
                "type": "metric",
                "properties": {
                  "metrics": [
                    [
                      "AWS/AutoScaling",
                      "GroupDesiredCapacity",
                      "AutoScalingGroupName",
                      "${module.autoscalinggroup_api.autoscalegroup_name}"
                    ],
                    [
                      "AWS/AutoScaling",
                      "GroupInServiceInstances",
                      "AutoScalingGroupName",
                      "${module.autoscalinggroup_api.autoscalegroup_name}"           
                    ]
                  ],
                  "period": 300,
                  "stat": "Average",
                  "region": "${var.region}",
                  "title": "API Target Group",
                  "liveData": true
                }
              }, 
              {
                "type": "metric",
                "properties": {
                  "metrics": [
                    [
                      "AWS/AutoScaling",
                      "GroupDesiredCapacity",
                      "AutoScalingGroupName",
                      "${module.autoscalinggroup_react.autoscalegroup_name}"
                    ],
                    [
                      "AWS/AutoScaling",
                      "GroupInServiceInstances",
                      "AutoScalingGroupName",
                      "${module.autoscalinggroup_react.autoscalegroup_name}"          
                    ]
                  ],
                  "period": 300,
                  "stat": "Average",
                  "region": "${var.region}",
                  "title": "REACT Target Group",
                  "liveData": true
                }
              }, 
              {
                "type": "metric",
                "properties": {
                    "metrics": [
                    [
                      "AWS/ApplicationELB",
                      "TargetResponseTime",
                      "LoadBalancer",
                      "${module.loadbalancer.mercury_app_lb_arnsuffix}"            
                    ],
                    [
                      "AWS/ApplicationELB",
                      "RequestCount",
                      "LoadBalancer",
                      "${module.loadbalancer.mercury_app_lb_arnsuffix}"            
                    ]
                  ],
                  "period": 300,
                  "stat": "Average",
                  "region": "${var.region}",
                  "title": "ALB ",
                  "liveData": true
                }
              }
            ]
          }
          EOF
}