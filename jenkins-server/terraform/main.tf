# main.tf - Konfiguracja Terraform dla instancji EC2 z Jenkinsem

# Definicja wymaganych dostawców dla tej konfiguracji.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# Konfiguracja dostawcy AWS.
provider "aws" {
  region = "us-east-1"
}

# Generowanie nowego 2048-bitowego klucza prywatnego RSA.
resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Tworzenie pary kluczy AWS przy użyciu klucza publicznego wygenerowanego przez zasób tls_private_key.
resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins_key"
  public_key = tls_private_key.rsa_key.public_key_openssh
}

# Zapisywanie wygenerowanego klucza prywatnego do lokalnego pliku o nazwie 'jenkins_key.pem'.
resource "local_file" "private_key_pem" {
  content         = tls_private_key.rsa_key.private_key_pem
  filename        = "jenkins_key.pem"
  file_permission = "0400" # Ustawienie uprawnień tylko do odczytu dla właściciela.
}

# Definicja grupy bezpieczeństwa dla instancji Jenkins.
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Zezwalaj na porty SSH i Jenkins"

  # Reguła wejściowa dla dostępu przez SSH z dowolnego adresu IP.
  # UWAGA: Dla większego bezpieczeństwa zaleca się ograniczenie tego do własnego adresu IP.
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Reguła wejściowa dla panelu internetowego Jenkins z dowolnego adresu IP.
  ingress {
    description = "Jenkins web panel"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Reguła wyjściowa zezwalająca na cały ruch wychodzący.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Tworzenie instancji EC2 dla Jenkinsa.
resource "aws_instance" "jenkins_server" {
  # AMI dla Ubuntu Server 22.04 LTS w regionie us-east-1.
  ami           = "ami-020cba7c55df1f615"
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name      = aws_key_pair.jenkins_key.key_name

  # Uruchamia skrypt instalacyjny Jenkinsa po uruchomieniu instancji.
  # Musisz utworzyć plik 'install_jenkins.sh' w tym samym folderze.
  user_data = file("install_jenkins.sh")

  tags = {
    Name = "Jenkins Server"
  }
}

# Wyświetlanie publicznego adresu IP serwera.
output "instance_public_ip" {
  value       = aws_instance.jenkins_server.public_ip
  description = "Publiczny adres IP serwera Jenkins."
}

# Wyświetlanie polecenia do zalogowania się na serwer przez SSH.
output "ssh_command" {
  value       = "ssh -i ${local_file.private_key_pem.filename} ubuntu@${aws_instance.jenkins_server.public_ip}"
  description = "Polecenie do połączenia się z serwerem Jenkins przez SSH."
}
