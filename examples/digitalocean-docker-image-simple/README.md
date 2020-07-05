# Docker Image — DigitalOcean

Deploys a single Docker image to a DigitalOcean Droplet.

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

resource "digitalocean_droplet" "app" {
  name   = "app"
  image  = "docker-18-04"
  region = "lon1"
  size   = "s-1vcpu-1gb"

  user_data = module.container-server.cloud_config # 👈
}

```

# Terraform

## Inputs

| Name   | Description                                                          | Type     | Default | Required |
| ------ | -------------------------------------------------------------------- | -------- | ------- | :------: |
| domain | The domain where the app will be hosted.                             | `string` | n/a     |   yes    |
| email  | Email address used when registering certificates with Let's Encrypt. | `string` | n/a     |   yes    |

## Outputs

| Name                  | Description |
| --------------------- | ----------- |
| docker_compose_config | n/a         |
