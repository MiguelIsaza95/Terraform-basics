provider "aws" {
  region = var.default_region
}

resource "aws_s3_bucket" "a" {
  bucket = "mai-s3-bucket-miguelisaza95"
  versioning {
    enabled = true
  }
}

resource "aws_iam_user" "my_iam_user" {
  name = var.iam_user_name
}
