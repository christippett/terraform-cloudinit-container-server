module "container-server" {
  source = "../.."

  domain = "app.${var.domain}"
  email  = var.email

  container = {
    image = "nginxdemos/hello"
  }
}

/* Instance ----------------------------------------------------------------- */

resource "aws_instance" "app" {
  ami             = "ami-0560993025898e8e8" # Amazon Linux 2
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.app.name]

  tags = {
    Name = "app"
  }

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
