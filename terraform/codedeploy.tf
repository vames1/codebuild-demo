# EC2 IAM Role
resource "aws_iam_role" "ec2_role" {
  name = "codedeploy-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach S3 read policy to EC2
resource "aws_iam_role_policy_attachment" "ec2_s3" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "codedeploy-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# CodeDeploy IAM Role
resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-demo-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codedeploy.amazonaws.com"
      }
    }]
  })
}

# Attach CodeDeploy policy
resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# Security Group for EC2
resource "aws_security_group" "web_sg" {
  name        = "codedeploy-web-sg"
  description = "Allow HTTP traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "CodeDeployWebSG"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y ruby wget
    cd /home/ec2-user
    wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto
    service codedeploy-agent start
  EOF

  tags = {
    Name = "CodeDeployWebServer"
  }
}

# CodeDeploy Application
resource "aws_codedeploy_app" "demo" {
  name             = "codedeploy-demo-app"
  compute_platform = "Server"
}

# CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "demo" {
  app_name              = aws_codedeploy_app.demo.name
  deployment_group_name = "codedeploy-demo-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "CodeDeployWebServer"
    }
  }

  deployment_style {
    deployment_type   = "IN_PLACE"
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
  }
}

# Outputs
output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

output "codedeploy_app_name" {
  value = aws_codedeploy_app.demo.name
}
