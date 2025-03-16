terraform {
  required_version = "1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }

}

provider "aws" {
  region  = "us-east-1"
  profile = "default"
  default_tags {
    tags = {
      owner       = "Aashi"
      Environment = ""
    }
  }

}

#####################################################################
#vpc 
resource "aws_vpc" "prj_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "Project_vpc"
  }

}

#public subnet1
resource "aws_subnet" "prj_pub_sn1" {
  vpc_id                  = aws_vpc.prj_vpc.id
  cidr_block              = "10.0.0.0/26"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "project_public_subnet1"
  }
}

#public subnet2
resource "aws_subnet" "prj_pub_sn2" {
  vpc_id                  = aws_vpc.prj_vpc.id
  cidr_block              = "10.0.0.64/26"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "project_public_subnet2"
  }
}

#private subnet
resource "aws_subnet" "prj_pvt_sn" {
  vpc_id                  = aws_vpc.prj_vpc.id
  cidr_block              = "10.0.0.128/25"
  map_public_ip_on_launch = false
  tags = {
    Name = "project_private_subnet"
  }

}

#public route table
resource "aws_route_table" "prj_pub_rt" {
  vpc_id = aws_vpc.prj_vpc.id
  tags = {
    Name = "project_public_rt"
  }

}

#private route table
resource "aws_route_table" "prj_pvt_rt" {
  vpc_id = aws_vpc.prj_vpc.id
  tags = {
    Name = "project_private_rt"
  }

}

#association with public route table for sub1
resource "aws_route_table_association" "prj_pub_rt_as1" {
  route_table_id = aws_route_table.prj_pub_rt.id
  subnet_id      = aws_subnet.prj_pub_sn1.id

}

#association with public route table for sub1
resource "aws_route_table_association" "prj_pub_rt_as2" {
  route_table_id = aws_route_table.prj_pub_rt.id
  subnet_id      = aws_subnet.prj_pub_sn2.id
}


#association with private route table
resource "aws_route_table_association" "prj_pvt_rt_as" {
  route_table_id = aws_route_table.prj_pvt_rt.id
  subnet_id      = aws_subnet.prj_pvt_sn.id

}

#internetn gateway
resource "aws_internet_gateway" "prj_igw" {
  vpc_id = aws_vpc.prj_vpc.id
  tags = {
    Name = "project_internet_gateway"
  }

}

#attachment to internet gateway
resource "aws_route" "prj_r_pub" {
  route_table_id         = aws_route_table.prj_pub_rt.id
  destination_cidr_block = var.prj_all_trafic
  gateway_id             = aws_internet_gateway.prj_igw.id

}

#nat gateway
resource "aws_nat_gateway" "prj_nat" {
  subnet_id     = aws_subnet.prj_pub_sn1.id
  allocation_id = aws_eip.prj_eip.id
  depends_on    = [aws_eip.prj_eip]
  tags = {
    Name = "project_nat_gateway"
  }
}

#attachment to nat gateway

resource "aws_route" "prj_r_pvt" {
  route_table_id         = aws_route_table.prj_pvt_rt.id
  destination_cidr_block = var.prj_all_trafic
  nat_gateway_id         = aws_nat_gateway.prj_nat.id
}


#elastic ip 
resource "aws_eip" "prj_eip" {
  domain = "vpc"
  tags = {
    Name = "Project_eip"
  }

}


#####################################################################
# ec2 template
resource "aws_launch_template" "project_lt" {
  name          = "web-app"
  image_id      = data.aws_ami.ami_id_linux.id
  instance_type = var.prj_instance_type
  key_name      = var.prj_key_name

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.prj_volume_size
      volume_type = var.prj_volume_type
    }
  }
  block_device_mappings {
    device_name = "/dev/sdf"
    ebs {
      volume_size = var.prj_volume_size
      volume_type = var.prj_volume_type
    }
  }
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.prj_sg.id]
  }

  user_data = filebase64("./userdata.sh")
  tags = {
    Name = "Project-web-app"
  }
}


#####################################################################
#security group
resource "aws_security_group" "prj_sg" {
  name   = "project-security-group"
  vpc_id = aws_vpc.prj_vpc.id
  tags = {
    Name = "http-ssh-security-group"
  }
  ingress {
    from_port   = var.prj_http_port
    to_port     = var.prj_http_port
    protocol    = "tcp"
    cidr_blocks = [var.prj_all_trafic]
  }
  ingress {
    from_port   = var.prj_ssh_port
    to_port     = var.prj_ssh_port
    protocol    = "tcp"
    cidr_blocks = [var.prj_all_trafic]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.prj_all_trafic]
  }

}

#####################################################################
#target group
resource "aws_lb_target_group" "prj_target_group" {
  name = "Project-target-group"
  # target_type = "alb"
  port     = var.prj_http_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.prj_vpc.id


}

#####################################################################
#load balancer
resource "aws_lb" "prj_loadbalancer" {
  name               = "project-load-balancer"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.prj_pub_sn1.id, aws_subnet.prj_pub_sn2.id]
  security_groups    = [aws_security_group.prj_sg.id]

}

#listening port of load balancer
resource "aws_lb_listener" "prj_lb_listener" {
  load_balancer_arn = aws_lb.prj_loadbalancer.arn
  port              = var.prj_http_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prj_target_group.arn

  }

}

#####################################################################
#creating a auto scalling group
resource "aws_autoscaling_group" "prj_autoscalling_group" {
  name             = "Project-auto-scaling-group"
  min_size         = 1
  max_size         = 2
  desired_capacity = 1
  launch_template {
    id      = aws_launch_template.project_lt.id
    version = "$Latest"
  }

  vpc_zone_identifier       = [aws_subnet.prj_pub_sn1.id, aws_subnet.prj_pub_sn2.id]
  health_check_grace_period = 60
  target_group_arns         = [aws_lb_target_group.prj_target_group.arn]

}

#attaching autoscaling group
resource "aws_autoscaling_attachment" "prj_autoscalling_attch" {
  autoscaling_group_name = aws_autoscaling_group.prj_autoscalling_group.id
  lb_target_group_arn    = aws_lb_target_group.prj_target_group.arn

}

