module "container-server" {
  source = "../.."

  domain = "app.${var.domain}"
  email  = var.email

  container = {
    image = "nginxdemos/hello"
  }
}

/* Instance ----------------------------------------------------------------- */
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "app" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.app.name]

  tags = {
    Name = "app"
  }

  key_name = "detjensrobert-onecommons"

  user_data = module.container-server.cloud_config
}

/* DNS ---------------------------------------------------------------------- */

resource "aws_route53_record" "app" {
  zone_id = var.zone_id
  name    = "app.${var.domain}"
  type    = "A"
  records = [aws_instance.app.public_ip]
  ttl     = "180"
}

/* Firewall ----------------------------------------------------------------- */

resource "aws_security_group" "app" {
  name = "allow_app"

  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
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
