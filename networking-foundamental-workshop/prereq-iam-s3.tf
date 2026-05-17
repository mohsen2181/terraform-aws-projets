# -------------------------
# EC2 IAM Role
# -------------------------

resource "aws_iam_role" "ec2_role" {
  name = "NetworkingWorkshopEC2Role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_s3_full_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# -------------------------
# EC2 Instance Profile
# -------------------------

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "NetworkingWorkshopInstanceProfile"
  path = "/"
  role = aws_iam_role.ec2_role.name
}

# -------------------------
# VPC Flow Logs IAM Role
# -------------------------

resource "aws_iam_role" "flow_logs_role" {
  name        = "NetworkingWorkshopFlowLogsRole"
  description = "Role to allow VPC Flow Logs to write to CloudWatch logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_logs_cloudwatch_write" {
  name = "CloudWatchLogsWrite"
  role = aws_iam_role.flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:NetworkingWorkshopFlowLogsGroup:*"
      }
    ]
  })
}

# -------------------------
# S3 Bucket for endpoint policy tests
# -------------------------

resource "aws_s3_bucket" "gateway_endpoint_bucket" {
  bucket = "networking-day-${var.aws_region}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_lifecycle_configuration" "gateway_endpoint_bucket_lifecycle" {
  bucket = aws_s3_bucket.gateway_endpoint_bucket.id

  rule {
    id     = "expire-objects-after-3-days"
    status = "Enabled"

    filter {}

    expiration {
      days = 3
    }
  }
}


resource "aws_iam_role_policy" "ec2_kms_list_aliases" {
  name = "AllowKMSListAliases"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:ListAliases",
          "kms:ListKeys"
        ]
        Resource = "*"
      }
    ]
  })
}
