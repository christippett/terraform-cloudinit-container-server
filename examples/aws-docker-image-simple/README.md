# Docker Image — AWS

Deploys a single Docker image to an AWS EC2 instance.

## Usage

```hcl
module "container-server" {
  source = "../.."

  domain = "app.${var.domain}"
  email  = var.email

  container = {
    image = "nginxdemos/hello"
  }
}

resource "aws_instance" "app" {
  ami             = "ami-0560993025898e8e8" # Amazon Linux 2
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.app.name]

  tags = {
    Name = "app"
  }

  user_data = module.container-server.cloud_config # 👈
}

```

# Terraform

## Inputs

| Name    | Description                                                          | Type     | Default | Required |
| ------- | -------------------------------------------------------------------- | -------- | ------- | :------: |
| domain  | The domain where the app will be hosted.                             | `string` | n/a     |   yes    |
| email   | Email address used when registering certificates with Let's Encrypt. | `string` | n/a     |   yes    |
| zone_id | Route53 Zone ID.                                                     | `string` | n/a     |   yes    |

## Outputs

| Name                  | Description |
| --------------------- | ----------- |
| docker_compose_config | n/a         |
