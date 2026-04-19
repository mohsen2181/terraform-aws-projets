############################################
# S3 bucket for CloudFront logs
############################################
resource "aws_s3_bucket" "logs" {
  bucket = "${var.bucket_name}-logs"

  force_destroy = true
}

############################################
# Block public access
############################################
resource "aws_s3_bucket_public_access_block" "logs_block" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################################
# REQUIRED for CloudFront logging
############################################
resource "aws_s3_bucket_ownership_controls" "logs_ownership" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

############################################
# REQUIRED for CloudFront logging
############################################
resource "aws_s3_bucket_acl" "logs_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.logs_ownership]

  bucket = aws_s3_bucket.logs.id
  acl    = "log-delivery-write"
}

############################################
# 🔥 NEW: Trigger Lambda on new log files
############################################
resource "aws_s3_bucket_notification" "logs_trigger" {
  bucket = aws_s3_bucket.logs.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.auto_block.arn
    events              = ["s3:ObjectCreated:*"]

    # must match your CloudFront config
    filter_prefix = "cloudfront-logs/"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
