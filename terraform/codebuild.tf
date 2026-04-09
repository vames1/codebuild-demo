# S3 bucket for build artifacts
resource "aws_s3_bucket" "artifacts" {
  bucket = "codebuild-artifacts-725115072836"

  tags = {
    Name = "CodeBuildArtifacts"
  }
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-demo-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for CodeBuild
resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodeBuild Project
resource "aws_codebuild_project" "demo" {
  name          = "codebuild-demo-project"
  description   = "Demo CodeBuild project"
  build_timeout = 5
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type      = "S3"
    location  = aws_s3_bucket.artifacts.bucket
    packaging = "ZIP"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/vames1/codebuild-demo.git"
    git_clone_depth = 1
    buildspec       = "buildspec.yml"
  }

  tags = {
    Name = "CodeBuildDemo"
  }
}

# Output
output "codebuild_project_name" {
  value = aws_codebuild_project.demo.name
}

output "artifacts_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}
