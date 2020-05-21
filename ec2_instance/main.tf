provider "aws" {
  region = var.default_region
}

resource "aws_vpc" "test" {
  cidr_block           = var.vpc_address
  tags                 = var.vpc_tags
  enable_dns_hostnames = true
}

resource "aws_subnet" "test_http" {
  vpc_id                  = aws_vpc.test.id
  cidr_block              = var.subnet_address
  map_public_ip_on_launch = "true"
  availability_zone       = var.subnet_zone
}

resource "aws_default_route_table" "route_table" {
  default_route_table_id = aws_vpc.test.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.test.id
}

resource "aws_security_group" "http_sg" {
  name   = var.sg_name
  vpc_id = aws_vpc.test.id
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

resource "aws_instance" "http_server" {
  ami                    = data.aws_ami.linux_latest.id
  key_name               = var.key_name
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.http_sg.id]
  subnet_id              = aws_subnet.test_http.id

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.aws_key_pair)
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd -y",
      "sudo service httpd start",
      "echo welcome to my web - Virtual server is at ${self.public_dns} | sudo tee /var/www/html/index.html"
    ]
  }
}
