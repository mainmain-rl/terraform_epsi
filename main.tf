# Configure the AWS Provider
provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}
######################################## RESEAU ########################################
# Create a VPC
resource "aws_vpc" "vpc_terraform" {
  cidr_block = "10.10.0.0/16"
  tags = {
    name = "vpc_terraform"
  }
}

# Create subnet
resource "aws_subnet" "subnet_1_terraform" {
  cidr_block = "10.10.1.0/24"
  vpc_id = aws_vpc.vpc_terraform.id
  tags = {
    Name = "subnet_1_terraform"
   }
}
resource "aws_subnet" "subnet_2_terraform" {
  cidr_block = "10.10.2.0/24"
  vpc_id = aws_vpc.vpc_terraform.id
  tags = {
    Name = "subnet_2_terraform"
   }
}
  # Create gateway
  resource "aws_internet_gateway" "internetgateway_terraform" {
  vpc_id = aws_vpc.vpc_terraform.id

  tags = {
    Name = "internetgateway_terraform"
  }
}

# Create routetable
resource "aws_route_table" "routetable_terraform" {
  vpc_id = aws_vpc.vpc_terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internetgateway_terraform.id
  }

  tags = {
    Name = "routetable_terraform"
  }
}
#Create association route table
resource "aws_route_table_association" "routetableassociation" {
  subnet_id      = aws_subnet.subnet_1_terraform.id
  route_table_id = aws_route_table.routetable_terraform.id
}
######################################## END RESEAU ########################################

#Create clé RSA 4096
resource "tls_private_key" "key_terraform" {
  algorithm   = "RSA"
  rsa_bits = "4096"
}
resource "aws_key_pair" "ec2-key-tf" {
  key_name   = "ec2-key-tf"
  public_key = tls_private_key.key_terraform.public_key_openssh
}

######################################## INSTANCE ########################################
#Create EC2
/*data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "ec2-test-1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.subnet_1_terraform.id
  key_name   = aws_key_pair.ec2-key-tf.id
  associate_public_ip_address = true
  user_data = file("${path.module}/post_install.sh")
  vpc_security_group_ids = [aws_security_group.allow_http.id, aws_security_group.allow_ssh_vpc.id]

  tags = {
    Name = "ec2-test-1"
  }
}
resource "aws_instance" "ec2-test-2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.subnet_1_terraform.id
  key_name   = aws_key_pair.ec2-key-tf.id
  associate_public_ip_address = true
  user_data = file("${path.module}/post_install.sh")
  vpc_security_group_ids = [aws_security_group.allow_http.id, aws_security_group.allow_ssh_vpc.id]

  tags = {
    Name = "ec2-test-2"
  }
}*/

##### LB #####
#Create loadbalancer
resource "aws_lb" "alb_terraform" {
  name               = "alb_terraform"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http.id]
  subnets            = ["aws_subnet.subnet_1_terraform.id", "aws_subnet.subnet_2_terraform.id"]
}
#Create lb target group
resource "aws_lb_target_group" "lb_target_group_tf" {
  name     = "lb_target_group_tf"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_terraform.id
}
#Create lb listner
resource "aws_lb_listener" "alb_listner_terraform" {
  load_balancer_arn = aws_lb.alb_terraform.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group_tf.arn
  }
}
#creation lb target groupe attachment
resource "aws_lb_target_group_attachment" "target_group_attachment_tf" {
  target_group_arn = aws_lb_target_group.lb_target_group_tf.arn
  target_id        = aws_instance.lb_target_group_tf.id
  port             = 80
}
##### END LB #####

##### ASG #####
#Auto-scalling-group
resource "aws_placement_group" "asg_placement_group_terraform" {
  name     = "asg_placement_group_terraform"
  strategy = "cluster"
}

resource "aws_autoscaling_group" "asg_terraform" {
  name                      = "asg_terraform"
  max_size                  = 3
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 4
  force_delete              = true
  placement_group           = aws_placement_group.asg_placement_group_terraform.id
  launch_configuration      = aws_launch_configuration.launch_configuration_terraform.name
  vpc_zone_identifier       = aws_subnet.subnet_1_terraform.id

  initial_lifecycle_hook {
    name                 = "asg_lifecycle_terraform"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  }

  timeouts {
    delete = "5m"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_terraform" {
  autoscaling_group_name = aws_autoscaling_group.asg_terraform.id
  alb_target_group_arn   = aws_alb_target_group.lb_target_group_tf.arn
}
#Create LAUNCH CONFIGURATION
resource "aws_launch_configuration" "launch_configuration_terraform" {
  image_id = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  security_groups = aws_security_group.allow_http.id
  user_data = file("${path.module}/post_install.sh")
}
##### END ASG #####
######################################## END INSTANCE ########################################

######################################## SECURITY GROUP ########################################
resource "aws_security_group" "allow_http" {
  name        = "allow_http_from_any"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.vpc_terraform.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}
resource "aws_security_group" "allow_ssh_vpc" {
  name        = "allow_ssh_from_vpc"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.vpc_terraform.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_terraform.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_vpc"
  }
}
######################################## END SECURITY GROUP ########################################

#OUTPUT
output "private_key" {
  value = tls_private_key.key_terraform.private_key_pem
}