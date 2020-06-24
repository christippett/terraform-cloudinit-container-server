# Docker Image — Google Cloud Platform

Deploys a single Docker image to a Compute Engine instance.

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
| cloud_dns_zone     | Cloud DNS zone name.                                                 | `string` | n/a     |   yes    |
| domain             | The domain where the app will be hosted.                             | `string` | n/a     |   yes    |
| letsencrypt_email  | Email address used when registering certificates with Let's Encrypt. | `string` | n/a     |   yes    |
| network_name       | The name of the network where the instance will be created.          | `string` | n/a     |   yes    |
| portainer_password | Password to log into Portainer. Must be hashed using `bcrypt`.       | `string` | n/a     |   yes    |
| project            | The ID of the project in which to provision resources.               | `string` | n/a     |   yes    |
| region             | Google Cloud region where the instance will be created.              | `string` | n/a     |   yes    |
| subnetwork_name    | The name of the subnet where the instance will be created.           | `string` | n/a     |   yes    |
| zone               | Google Cloud region zone where the instance will be created.         | `string` | n/a     |   yes    |

## Outputs

| Name                  | Description |
| --------------------- | ----------- |
| docker_compose_config | n/a         |
