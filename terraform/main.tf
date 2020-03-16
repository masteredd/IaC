provider "aws" {
  region = "eu-north-1"
  profile = "myaws"
  shared_credentials_file = "~/.aws/credentials"
}

# create VPC
resource "aws_vpc" "myVPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "myVPC"
  }
}

# create internet gateway
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id
  tags = {
    Name = "myIGW"
  }  
}

resource "aws_route_table" "myRT" {
    vpc_id = aws_vpc.myVPC.id
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        //CRT uses this IGW to reach internet
        gateway_id = aws_internet_gateway.myIGW.id
    }
    
    tags = {
        Name = "myRT"
    }
}

resource "aws_route_table_association" "myRTassociation" {
  subnet_id = aws_subnet.mySubnet.id
  route_table_id = aws_route_table.myRT.id
}


# create subnet for myVPC
resource "aws_subnet" "mySubnet" {
  vpc_id = aws_vpc.myVPC.id
  availability_zone = "eu-north-1a"
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "mySubnet"
  }
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  ingress {
    description = "allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow flask app"
    from_port   = 5000
    to_port     = 5000
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
    Name = "allow_ssh_http"
  }  
}

resource "aws_instance" "my-instance" {
	ami = "ami-0b7937aeb16a7eb94"
	instance_type = "t3.micro"
  subnet_id = aws_subnet.mySubnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  key_name = "stockholm_key"
  tags = {
    Name = "myServer"
  }
}