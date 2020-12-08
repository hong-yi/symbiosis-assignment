provider "aws" {
  region = "ap-southeast-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "template_file" "userdata" {
    template = file("userdata.tpl")
}

resource "aws_vpc_endpoint" "s3" {
    vpc_id = module.vpc.vpc_id
    service_name = "com.amazonaws.ap-southeast-1.s3"
    vpc_endpoint_type = "Gateway"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-symbiosis"
  cidr = "10.0.0.0/16"

  azs             = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  map_public_ip_on_launch = false

  enable_nat_gateway = true
  create_igw = true

  database_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  public_dedicated_network_acl = true
  public_inbound_acl_rules = [
    {
        "cidr_block": "0.0.0.0/0",
        "from_port": 80,
        "protocol": "tcp",
        "rule_action": "allow",
        "rule_number": 100,
        "to_port": 80
    },
    {
        "cidr_block": "0.0.0.0/0",
        "from_port": 443,
        "protocol": "tcp",
        "rule_action": "allow",
        "rule_number": 200,
        "to_port": 443
    },
    {
        "cidr_block": "0.0.0.0/0",
        "from_port": 1024,
        "protocol": "tcp",
        "rule_action": "allow",
        "rule_number": 300,
        "to_port":65535
    },
    {
        "cidr_block": "0.0.0.0/0",
        "from_port": 22,
        "protocol": "tcp",
        "rule_action": "allow",
        "rule_number": 400,
        "to_port":22
    },
    {
        "cidr_block": "0.0.0.0/0",
        "from_port": 3000,
        "protocol": "tcp",
        "rule_action": "allow",
        "rule_number": 500,
        "to_port":3000
    },
  ]

  public_outbound_acl_rules = [
    {
        "cidr_block": "0.0.0.0/0",
        "from_port": 80,
        "protocol": "tcp",
        "rule_action": "allow",
        "rule_number": 100,
        "to_port": 80
    },
    {
        "cidr_block": "0.0.0.0/0",
        "from_port": 443,
        "protocol": "tcp",
        "rule_action": "allow",
        "rule_number": 200,
        "to_port": 443
    },
    {
        "cidr_block": "0.0.0.0/0",
        "from_port": 1024,
        "protocol": "tcp",
        "rule_action": "allow",
        "rule_number": 300,
        "to_port":65535
    },
    {
        "cidr_block": "10.0.0.0/16",
        "from_port": 3306,
        "protocol": "tcp",
        "rule_action": "allow",
        "rule_number": 400,
        "to_port":3306
    },
    {
        "cidr_block": "10.0.0.0/16",
        "from_port": 22,
        "protocol": "tcp",
        "rule_action": "allow",
        "rule_number": 500,
        "to_port": 22
    },
    {
        "cidr_block": "10.0.0.0/16",
        "from_port": 3000,
        "protocol": "tcp",
        "rule_action": "allow",
        "rule_number": 600,
        "to_port":3000
    },
    ] 

  database_dedicated_network_acl = true
  database_inbound_acl_rules = [
    {
        "cidr_block": "10.0.0.0/16",
        "from_port": 3306,
        "protocol": "tcp",
        "rule_action": "allow",
        "rule_number": 100,
        "to_port":3306 
    },
    {
        "cidr_block": "10.0.0.0/16",
        "from_port": 32768,
        "protocol": "tcp",
        "rule_action": "allow",
        "rule_number": 200,
        "to_port":65535 
    }
]
database_outbound_acl_rules = [
    {
        "cidr_block": "10.0.0.0/16",
        "from_port": 3306,
        "protocol": "tcp",
        "rule_action": "allow",
        "rule_number": 100,
        "to_port":3306 
    },
        {
        "cidr_block": "10.0.0.0/16",
        "from_port": 32768,
        "protocol": "tcp",
        "rule_action": "allow",
        "rule_number": 200,
        "to_port":65535 
    }
]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_vpc_endpoint_route_table_association" "public_s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id = module.vpc.public_route_table_ids[0]
}

module "public_sg" {
    source = "terraform-aws-modules/security-group/aws"

    name = "web_service"
   vpc_id = module.vpc.vpc_id

    ingress_with_cidr_blocks = [
        {
            from_port = 80
            to_port = 80
            protocol = "tcp"
            description = "http"
            cidr_blocks = "10.0.0.0/16"
        },
        {
            from_port = 3000
            to_port = 3000
            protocol = "tcp"
            description = "allow node"
            cidr_blocks = "0.0.0.0/0"
        },
        {
            from_port = 3306
            to_port = 3306
            protocol = "tcp"
            description = "allow mysql"
            cidr_blocks = "10.0.0.0/16"
        },
        {
            from_port = 443
            to_port = 443
            protocol = "tcp"
            description = "allow https"
            cidr_blocks = "0.0.0.0/0"
        },
        {
            from_port = 22
            to_port = 22
            protocol = "tcp"
            description = "allow ssh"
            cidr_blocks = "10.0.0.0/16"
        }
    ]

        egress_with_cidr_blocks = [
        {
            from_port = 80
            to_port = 80
            protocol = "tcp"
            description = "http"
            cidr_blocks = "10.0.0.0/16"
        },
        {
            from_port = 3306
            to_port = 3306
            protocol = "tcp"
            description = "allow mysql"
            cidr_blocks = "10.0.0.0/16"
        },
        {
            from_port = 443
            to_port = 443
            protocol = "tcp"
            description = "allow https"
            cidr_blocks = "0.0.0.0/0"
        },
        {
            from_port = 1024
            to_port = 65535
            protocol = "tcp"
            description = "allow ephemeral ports"
            cidr_blocks = "10.0.0.0/16"
        }
    ]
}

module "database_sg" {
    source = "terraform-aws-modules/security-group/aws"

    name = "web_service"
    vpc_id = module.vpc.vpc_id

    ingress_with_cidr_blocks = [
        {
            from_port = 3306
            to_port = 3306
            protocol = "tcp"
            description = "allow mysql"
            cidr_blocks = "10.0.0.0/16"
        },
    ]
}

module "db" {
    source = "terraform-aws-modules/rds-aurora/aws"

    name = "db-symbiosis"

    engine = "aurora-mysql"
    engine_version = "5.7.mysql_aurora.2.03.2"
    database_name = "symbiosis"
    vpc_id = module.vpc.vpc_id
    vpc_security_group_ids= [module.database_sg.this_security_group_id]
    subnets = module.vpc.database_subnets

    instance_type = "db.t3.medium"
    storage_encrypted               = false
    apply_immediately               = true
    skip_final_snapshot = true
    monitoring_interval             = 10
    replica_count = 2
    port = "3306"

    username = ""
    password = ""
}

resource "aws_autoscaling_group" "asg_web" {
    name = "asg-web"

    launch_configuration = aws_launch_configuration.lc_web.name
    vpc_zone_identifier = module.vpc.public_subnets
    min_size = 2
    max_size = 4
    desired_capacity = 2

    tags = [ {
      "key" = "application"
      "value" = "web"
      "propagate_at_launch" = true
    },
    
    {
        "key" = "name"
        "value" = "webapp"
        "propagate_at_launch" = true    
    } ]

    target_group_arns = module.nlb.target_group_arns
}

resource "aws_launch_configuration" "lc_web" {
    name = "lc_web_v04"
    image_id = "ami-008d976934fcff622"
    instance_type = "t3.medium"
    security_groups = [module.public_sg.this_security_group_id]
    key_name = "keypair-nodejsami"
    iam_instance_profile = "iam-instanceprofile-webapp"
    user_data = data.template_file.userdata.rendered

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_policy" "scaleup" {
    name = "asp-web-scaleup"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = aws_autoscaling_group.asg_web.name
}

resource "aws_autoscaling_policy" "scaledown" {
    name = "asp-web-scaledown"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = aws_autoscaling_group.asg_web.name
}

resource "aws_cloudwatch_metric_alarm" "cwma_web_cpu_util_high" {
    alarm_name = "cwma_web_cpu_util_high"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 2
    statistic = "Average"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    threshold = 75
    period = 300

    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.asg_web.name
    }

    alarm_actions = [ aws_autoscaling_policy.scaleup.arn ]
}

resource "aws_cloudwatch_metric_alarm" "cwma_web_cpu_util_low" {
    alarm_name = "cwma_web_cpu_util_low"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = 2
    period = 300
    statistic = "Average"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    threshold = 35

    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.asg_web.name
    }

    alarm_actions = [ aws_autoscaling_policy.scaledown.arn ]

}

module "nlb" {
    source = "terraform-aws-modules/alb/aws"

    name = "lb-n-symbiosis"
    subnets = module.vpc.public_subnets
    internal = false
    load_balancer_type = "network"
    vpc_id = module.vpc.vpc_id
    

    http_tcp_listeners = [
        {
            port = 80
            protocol = "TCP"
            vpc_id = module.vpc.vpc_id
        }
    ]

    target_groups = [
        {
            name_prefix      = "pref-"
            backend_protocol = "TCP"
            backend_port     = 3000
            target_type      = "instance"
            vpc_id = module.vpc.vpc_id
        }
    ]
}