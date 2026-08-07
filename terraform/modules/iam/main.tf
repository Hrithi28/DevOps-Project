# ─── Jenkins EC2 Role (access ECR + EKS) ─────────────────────────────────────
resource "aws_iam_role" "jenkins" {
  name = "${var.project_name}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "jenkins_policy" {
  name        = "${var.project_name}-jenkins-policy"
  description = "Allow Jenkins to push to ECR and manage EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_policy_attach" {
  policy_arn = aws_iam_policy.jenkins_policy.arn
  role       = aws_iam_role.jenkins.name
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.project_name}-jenkins-profile"
  role = aws_iam_role.jenkins.name
}

# ─── Outputs ──────────────────────────────────────────────────────────────────
output "jenkins_role_arn"     { value = aws_iam_role.jenkins.arn }
output "jenkins_profile_name" { value = aws_iam_instance_profile.jenkins.name }
