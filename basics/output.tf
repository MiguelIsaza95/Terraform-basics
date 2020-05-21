output "my_s3_bucket_versioning" {
  value = aws_s3_bucket.a.versioning[0].enabled
}

output "my_s3_bucket_complete_details" {
  value = aws_s3_bucket.a.versioning
}

output "my_iam_user_details" {
  value = aws_iam_user.my_iam_user
}
