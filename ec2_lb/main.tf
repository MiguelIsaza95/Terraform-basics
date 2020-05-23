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
  count                   = length(var.subnet_zone)
  cidr_block              = cidrsubnet(var.vpc_address, 4, count.index)
  map_public_ip_on_launch = "true"
  availability_zone       = element(var.subnet_zone, count.index)

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

resource "aws_security_group" "elb_sg" {
  name   = "elb_sg"
  vpc_id = aws_vpc.test.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }


}

resource "aws_instance" "http_server" {
  count                  = length(var.subnet_zone)
  ami                    = data.aws_ami.linux_latest.id
  key_name               = var.key_name
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.http_sg.id]

  subnet_id = aws_subnet.test_http[count.index].id

  tags = {
    name : "http_servers_$(subnet_id)"
  }

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

resource "aws_elb" "elb" {
  name = "elb"
  #availability_zones = var.subnet_zone
  subnets = aws_subnet.test_http.*.id
  # subnets helps to attach the lb to your current vpc
  # we can define az or subnets, but just one of them.
  instances       = aws_instance.http_server.*.id
  security_groups = [aws_security_group.elb_sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}


#resource "aws_elb_attachment" "baz" {
#  count    = length(var.subnet_zone)
#  elb      = aws_elb.elb.id
#  instance = element(aws_instance.http_server.*.id, count.index)
#}
