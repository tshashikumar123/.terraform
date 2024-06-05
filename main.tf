resource "aws_vpc" "shashi-vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "shashi-vpc"
  }
}
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.shashi-vpc.id
}
resource "aws_subnet" "public-subnet-1" {
  vpc_id                  = aws_vpc.shashi-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "public-subnet-1"
  }
}
resource "aws_route_table" "route-1" {
  vpc_id = aws_vpc.shashi-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = {
    Name = "route-1"
  }

}
resource "aws_route_table_association" "route-1" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.route-1.id

}
resource "aws_security_group" "sg-1" {
  vpc_id = aws_vpc.shashi-vpc.id

  # Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-SG"
  }
}
resource "aws_instance" "ubuntu_image" {
    ami = "ami-04b70fa74e45c3917"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public-subnet-1.id
    vpc_security_group_ids = [aws_security_group.sg-1.id]
    associate_public_ip_address = true  # Enable auto-assigning public IP
    user_data = <<-EOF
                 #!/bin/bash
                 apt-get update
                 apt-get install -y apache2
                 systemctl enable apache2
                 systemctl start apache2
                 EOF
}
resource "aws_network_interface" "interface" {
  subnet_id       = aws_subnet.public-subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.sg-1.id]
}
resource "aws_eip" "my_ip" {
vpc = true
}
resource "aws_eip_association" "my_eip_association" {
  network_interface_id = aws_network_interface.interface.id
  allocation_id = aws_eip.my_ip.id
}
resource "aws_s3_bucket" "bucket-111828" {
  bucket = "bucket-111828"
  acl ="private"
  }
resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name = "terraform-dynamoDB-state"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20
 
  attribute {
    name = "LockID"
    type = "S"
  }
}
terraform {
  backend "s3" {
    bucket = "bucket-111828"
    dynamodb_table = "terraform-dynamoDB-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
