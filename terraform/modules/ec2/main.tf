# ─── Security Group for Jenkins ───────────────────────────────────────────────
resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Security group for Jenkins EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "Jenkins web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict to your IP in production
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict to your IP in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-jenkins-sg" }
}

# ─── EC2 Instance ─────────────────────────────────────────────────────────────
resource "aws_instance" "jenkins" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.jenkins.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    encrypted             = true
  }

  # Bootstrap Jenkins on first boot
  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    project_name = var.project_name
  }))

  tags = { Name = "${var.project_name}-jenkins-server" }
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.project_name}-jenkins-ec2-profile"
  role = split("/", var.jenkins_role_arn)[1]
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}
output "jenkins_instance_id"     { value = aws_instance.jenkins.id }
output "jenkins_security_group"  { value = aws_security_group.jenkins.id }
