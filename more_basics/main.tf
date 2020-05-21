provider "aws" {
  region = var.default_region
}

resource "aws_iam_user" "my_iam_users" {
  count = 1
  name  = "${var.iam_user_name}_${count.index}"
}
