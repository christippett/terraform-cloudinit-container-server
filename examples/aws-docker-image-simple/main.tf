module "docker-server" {
  source = "../.."

  domain            = "portainer.${var.domain}"
  letsencrypt_email = var.letsencrypt_email

  container = {
    image   = "portainer/portainer"
    command = "--admin-password ${replace(var.portainer_password, "$", "$$")}"
    ports   = ["9000"]
    volumes = ["/var/run/docker.sock:/var/run/docker.sock:ro"]
  }
}

/* Instance ----------------------------------------------------------------- */

resource "aws_instance" "portainer" {
  ami             = "ami-0560993025898e8e8" # Amazon Linux 2
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.portainer.name]

  tags = {
    Name = "portainer"
  }

  user_data = module.docker-server.cloud_config
}

/* DNS ---------------------------------------------------------------------- */

resource "aws_route53_record" "portainer" {
  zone_id = var.zone_id
  name    = "portainer.${var.domain}"
  type    = "A"
  records = [aws_instance.portainer.public_ip]
  ttl     = "180"
}

/* Firewall ----------------------------------------------------------------- */

resource "aws_security_group" "portainer" {
  name = "allow_portainer"

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
