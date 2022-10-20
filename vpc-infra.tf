terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.33.0"
    }
  }

  backend "s3" {
    bucket = "terraform-webapp-project"
    key    = "state"
    region = "ap-south-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# creating the VPC 
resource "aws_vpc" "demo-vpc" {
  cidr_block       = "10.10.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Demo-VPC"
  }
}

# creating the Subnet
resource "aws_subnet" "demo-subnet-1a" {
  vpc_id     = aws_vpc.demo-vpc.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "Demo-Subnet-1A"
  }
}

resource "aws_subnet" "demo-subnet-1b" {
  vpc_id     = aws_vpc.demo-vpc.id
  cidr_block = "10.10.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "Demo-Subnet-1B"
  }
}

#creating the EC2



#Creating Internet Gateway
resource "aws_internet_gateway" "Demo-IG" {
  vpc_id = aws_vpc.demo-vpc.id

  tags = {
    Name = "Demo-IG"
  }
}

#Creating Route Table
resource "aws_route_table" "webapp-route-table" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Demo-IG.id
  }

    tags = {
    Name = "webapp-route-table"
  }
}

#Creating Route Table Association
resource "aws_route_table_association" "webapp-RT-association-1A" {
  subnet_id      = aws_subnet.demo-subnet-1a.id
  route_table_id = aws_route_table.webapp-route-table.id
}

resource "aws_route_table_association" "webapp-RT-association-1B" {
  subnet_id      = aws_subnet.demo-subnet-1b.id
  route_table_id = aws_route_table.webapp-route-table.id
}

#Creating Target group for LB

resource "aws_lb_target_group" "Webapp-LB-Target-group" {
  name     = "Webapp-LB-Target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo-vpc.id
}


#Creating LB target group attachment

resource "aws_lb_target_group_attachment" "Webapp-LB-target-group-attachment1" {
   target_group_arn = aws_lb_target_group.Webapp-LB-Target-group.arn
   target_id        = aws_instance.Webapp1.id
   port             = 80
 }

resource "aws_lb_target_group_attachment" "Webapp-LB-target-group-attachment2" {
   target_group_arn = aws_lb_target_group.Webapp-LB-Target-group.arn
   target_id        = aws_instance.Webapp2.id
   port             = 80
  }

#Creating the Load Balancer

resource "aws_lb" "webapp-LB" {
  name               = "webapp-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_80-for-LB.id]
  subnets            = [aws_subnet.demo-subnet-1a.id,aws_subnet.demo-subnet-1b.id]

  

  tags = {
    Environment = "production"
  }
}


# Creating LB listen 

resource "aws_lb_listener" "Webapp-LB-listener" {
  load_balancer_arn = aws_lb.webapp-LB.arn
  port              = "80"
  protocol          = "HTTP"
  

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Webapp-LB-Target-group.arn
  }
}



# Creating AWS Autoscalling

resource "aws_launch_template" "Webapp-launch-template" {
  name_prefix   = "Webapp"
  image_id      = "ami-09b35fd82c23b4b64"
  instance_type = "t2.micro"
  key_name = "first-linux-instance-25"
  vpc_security_group_ids = [aws_security_group.allow_80_22.id]
}

resource "aws_autoscaling_group" "web-ASG" {
 # availability_zones = ["ap-south-1a,ap-south-1b"]
  desired_capacity   = 2
  max_size           = 3
  min_size           = 2
  vpc_zone_identifier = [aws_subnet.demo-subnet-1a.id,aws_subnet.demo-subnet-1b.id]

  launch_template {
    id      = aws_launch_template.Webapp-launch-template.id
    version = "$Latest"
  }
}


