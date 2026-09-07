# ==============================================================================
# EC2 INSTANCE ROLE
# ==============================================================================

resource "aws_iam_role" "ec2" {
  name = "${var.project}-${var.environment}-ec2-role"

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

  tags = {
    Name = "${var.project}-${var.environment}-ec2-role"
  }
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = {
    Name = "${var.project}-${var.environment}-ec2-profile"
  }
}

# ==============================================================================
# DEVELOPER USER
# ==============================================================================

resource "aws_iam_user" "developer" {
  name = "${var.project}-${var.environment}-developer"

  tags = {
    Name = "${var.project}-${var.environment}-developer"
  }
}

resource "aws_iam_user_policy_attachment" "developer_readonly" {
  user       = aws_iam_user.developer.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ==============================================================================
# CI/CD PIPELINE USER
# ==============================================================================

resource "aws_iam_user" "cicd" {
  name = "${var.project}-${var.environment}-cicd"

  tags = {
    Name = "${var.project}-${var.environment}-cicd"
  }
}

resource "aws_iam_user_policy" "cicd_deploy" {
  name = "${var.project}-${var.environment}-cicd-policy"
  user = aws_iam_user.cicd.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformDeployPermissions"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "rds:*",
          "s3:*",
          "iam:GetRole",
          "iam:GetInstanceProfile",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "*"
      }
    ]
  })
}