# Docker Image — AWS

Deploys a single Docker image to an AWS EC2 instance.

## Usage

```hcl
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

```

# Terraform

## Inputs

| Name               | Description                                                          | Type     | Default | Required |
| ------------------ | -------------------------------------------------------------------- | -------- | ------- | :------: |
| domain             | The domain where the app will be hosted.                             | `string` | n/a     |   yes    |
| letsencrypt_email  | Email address used when registering certificates with Let's Encrypt. | `string` | n/a     |   yes    |
| portainer_password | Password to log into Portainer. Must be hashed using `bcrypt`.       | `string` | n/a     |   yes    |
| zone_id            | Route53 Zone ID.                                                     | `string` | n/a     |   yes    |

## Outputs

| Name                  | Description |
| --------------------- | ----------- |
| docker_compose_config | n/a         |
