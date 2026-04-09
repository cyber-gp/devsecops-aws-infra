# IAM role for EC2 with S3 access
resource "aws_iam_role" "s3_full_access_role" {
  name = "${var.environment}-${var.project_name}-s3-full-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach S3 full access policy
resource "aws_iam_role_policy_attachment" "s3_full_access_policy_attachment" {
  role       = aws_iam_role.s3_full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Instance profile for EC2 to assume role
resource "aws_iam_instance_profile" "s3_full_access_instance_profile" {
  name = "${var.environment}-${var.project_name}-instance-role"
  role = aws_iam_role.s3_full_access_role.name
}