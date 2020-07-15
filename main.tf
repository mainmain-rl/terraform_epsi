# Configure the AWS Provider
provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}
#################### RESEAU ####################
# Create a VPC
resource "aws_vpc" "vpc_terraform" {
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "vpc_terraform"
    Env = "tp"
  }
}

# Create subnet
resource "aws_subnet" "subnet_1_terraform" {
  cidr_block = "10.10.1.0/24"
  vpc_id = aws_vpc.vpc_terraform.id
  
  tags = {
    Name = "subnet_1_terraform"
    Env = "tp"
   }
  }
  # Create gateway
  resource "aws_internet_gateway" "internetgateway_terraform" {
  vpc_id = aws_vpc.vpc_terraform.id

  tags = {
    Name = "internetgateway_terraform"
    Env = "tp"
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
    Env = "tp"
  }
}

#Create association route table
resource "aws_route_table_association" "routetableassociation" {
  subnet_id      = aws_subnet.subnet_1_terraform.id
  route_table_id = aws_route_table.routetable_terraform.id
}
#################### END RESEAU ####################

#Create clé RSA 4096
resource "tls_private_key" "key_terraform" {
  algorithm   = "RSA"
  rsa_bits = "4096"
}
resource "aws_key_pair" "ec2-key-tf" {
  key_name   = "ec2-key-tf"
  public_key = tls_private_key.key_terraform.public_key_openssh
}

#################### INSTANCE ####################
#Create EC2
data "aws_ami" "ubuntu" {
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
}


#################### END INSTANCE ####################

#################### SECURITY GROUP ####################
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
#################### END SECURITY GROUP ####################

#OUTPUT
output "private_key" {
  value = tls_private_key.key_terraform.private_key_pem
}