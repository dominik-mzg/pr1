provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH and Jenkins web access"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins Web"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins" {
  ami                    = "ami-020cba7c55df1f615" 
  instance_type          = "t3.small"
  key_name               = "prkey"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  tags = {
    Name = "jenkins-server"
  }
}
