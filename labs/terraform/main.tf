provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "laboratorio" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet-1" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.laboratorio.id
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1a"
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.laboratorio.id
}

resource "aws_route_table" "prod-public-crt" {
    vpc_id = aws_vpc.laboratorio.id
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        //CRT uses this IGW to reach internet
        gateway_id = aws_internet_gateway.igw.id 
    }
}

resource "aws_route_table_association" "prod-crta-public-subnet-1"{
    subnet_id = aws_subnet.subnet-1.id
    route_table_id = aws_route_table.prod-public-crt.id
}

resource "aws_security_group" "ssh" {
  name        = "allow_ssh"
  vpc_id      = aws_vpc.laboratorio.id 

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


resource "aws_instance" "instancia" {
  ami = "ami-0c101f26f147fa7fd"
  instance_type = "t2.micro"
  tags = {
    Name = "ec2-laboratorio-tf"
  }
  key_name = "terraform_ec2_key"
  associate_public_ip_address = true
  subnet_id = aws_subnet.subnet-1.id
  security_groups = [aws_security_group.ssh.id]
}

output "instance_ip" {
  description = "The public ip for ssh access"
  value       = aws_instance.instancia.public_ip
}

resource "aws_key_pair" "terraform_ec2_key" {
	key_name = "terraform_ec2_key"
  public_key = file("/home/vboxuser/.ssh/id_rsa.pub")
}
