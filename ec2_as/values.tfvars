default_region = "us-east-1"
vpc_name       = "Test_VPC"
vpc_tags = {
  Name        = "Test_VPC"
  Environment = "Test"
}
vpc_address = "10.0.0.0/16"
subnet_zone = ["us-east-1a", "us-east-1b", "us-east-1c"]
sg_name     = "http_sg"
ingress_rules = [
  {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
]

egress_rules = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
]
key_name      = "linux_key"
instance_type = "t2.micro"
aws_key_pair  = "/home/devops/Documents/aws_keys/linux_key.pem"
