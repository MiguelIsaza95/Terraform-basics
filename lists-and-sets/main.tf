provider "aws" {
  region = var.default_region
}

resource "aws_iam_user" "my_iam_users" {
  #count = length(var.names)
  #name  = var.names[count.index]
  for_each = toset(var.names)
  name     = each.value
}
