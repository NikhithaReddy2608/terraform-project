terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}




# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# Create a VPC
resource "aws_vpc" "south-vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name =  "south-vpc"
  }
}

# Create the first private subnet
resource "aws_subnet" "south-subnet1" {
  vpc_id                  = aws_vpc.south-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false
  
  tags = {
    Name = "south-subnet1"
  }
  
}

# Create the second private subnet
resource "aws_subnet" "south-subnet2" {
  vpc_id                  = aws_vpc.south-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = false
  
  tags = {
    Name = "south-subnet2"
  }
  
}

# Create the first public subnet
resource "aws_subnet" "south-subnet3" {
  vpc_id                  = aws_vpc.south-vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "south-subnet3"
  }
  
}

# Create the second public subnet
resource "aws_subnet" "south-subnet4" {
  vpc_id                  = aws_vpc.south-vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "south-subnet4"
  }
  
}

# Create the keypair
resource "aws_key_pair" "south-key" {
  key_name   = "south-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDHyUGzb8ZnNxP+IWxriOPG7Bgcgyric3KMi7Tq6grfmf20u7BUEMaNtynC1rGNppmBeoWpg1/lntLWNh003vb6nU7/onv3KnwFudhXGaqCAAgF5mWLK7n5MTv/oojlzYL0bSrRBzPxzDzGrX3q+Q0JrCrnSM5IZdpx034HzSl2g+ZRisHcCRiN8fTW0rMaJ+HbAvY83Vp3kiIY4YgZTFjhTIul4+ek8DtqRMkwSk4J6wLTRm/PSCpKV1aCQCGSqal1YLkGHfjyKA/lZHmaVV1w4HBBsWBBFTQ5mv4U9I5jYQDoUfzTTWjE4GiP/WAthVE4e9EUU7E2sywpdEBflmiDZxw/eqkMZmJTVRXyBV7Z0vOcH2ZvnToeFORJP+0mDQYV6Cwk06sqbP5g6Sg06T0kjVgJEJ+4Q619UOx+ORG81a+VN79Ucwq7dl3BzZMXE+UVch2h1SPWRZItOBvoPV6tKGbUXvAv12UxLqf5h8RyVtiWxHMBgdrAjfqG6FTuDPM= Nikhitha@Sundeep"

}

# Create the securitygroup
resource "aws_security_group" "south-SG" {
  name        = "south-SG"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.south-vpc.id

  ingress {
    description      = "SSH from PC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description = "HTTP from PC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }
    tags = {
       Name = "south-SG"
   }
  
}

# Create the internet gateway
resource "aws_internet_gateway" "south-IG" {
  vpc_id = aws_vpc.south-vpc.id

  tags = {
    Name = "south-IG"
  }
  
}

# Create the route table
resource "aws_route_table" "south-RT" {
  vpc_id = aws_vpc.south-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.south-IG.id
  }

   
    tags = {
     Name = "south-RT"
  }
  
  
}

# Create the route table associate
resource "aws_route_table_association" "south-RTA1" {
  subnet_id      = aws_subnet.south-subnet3.id
  route_table_id = aws_route_table.south-RT.id
}
resource "aws_route_table_association" "south-RTA2" {
  subnet_id      = aws_subnet.south-subnet4.id
  route_table_id = aws_route_table.south-RT.id
}

# Create target group
resource "aws_lb_target_group" "south-TG" {
  name     = "cardwebsite"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.south-vpc.id
  
  tags = {
    Name = "south-TG"
  }
}

#creating listener
resource "aws_lb_listener" "south-listener" {
  load_balancer_arn = aws_lb.south-loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"
default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.south-TG.arn
  }
}

#creating load balancer
resource "aws_lb" "south-loadbalancer" {
  name               = "cardwebsite"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.south-SG.id]
  subnets            = [aws_subnet.south-subnet3.id,aws_subnet.south-subnet4.id]

  #enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

#creating launch template
resource "aws_launch_template" "south-LT" {
  name = "south-LT"
  image_id = "ami-0f5ee92e2d63afc18"
  instance_type = "t2.micro"
  key_name = aws_key_pair.south-key.id
  monitoring {
    enabled = true
  }

  #network_interfaces {
   # associate_public_ip_address = true
  #}

  placement {
    availability_zone = "ap-south-1a"
  }

  vpc_security_group_ids = [aws_security_group.south-SG.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "south-instance-ASG"
    }
  }

  user_data = filebase64("userdata.sh")
}

#creating ASG
resource "aws_autoscaling_group" "south-ASG" {
  vpc_zone_identifier = [aws_subnet.south-subnet3.id,aws_subnet.south-subnet4.id]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2

  launch_template {
    id      = aws_launch_template.south-LT.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.south-TG.arn]
}
