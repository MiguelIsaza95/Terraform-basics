resource " aws_launch_configuration" "as_conf" {
  name                        = "http_server_config"
  image_id                    = data.aws_ami.linux_latest.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  security_groups             = [aws_security_group.http_sg.id]
  associate_public_ip_address = true
  user_data                   = <<-EOF
#!bin/bash
sudo yum install httpd -y
sudo service httpd start
echo "welcome to my web - Virtual server is at" ${self.public_dns} | sudo tee /var/www/html/index.html
EOF

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "as_http" {
  name                 = "http-autoscaling"
  max_size             = 5
  min_size             = 2
  desired_capacity     = 2
  health_check_type    = "ELB"
  load_balancers       = [aws_elb.elb.name]
  vpc_zone_identifier  = aws_subnet.test_http.*.id
  launch_configuration = aws_launch_configuration.as_conf.name
  force_delete         = true
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "http_policy" {
  name                   = "http_policy"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.as_http.id
}
