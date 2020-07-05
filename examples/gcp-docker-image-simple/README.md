# Docker Image — Google Cloud Platform

Deploys a single Docker image to a Compute Engine instance.

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

resource "google_compute_instance" "app" {
  name         = "app"
  project      = var.project
  zone         = "${var.region}-a"
  machine_type = "e2-small"
  tags         = ["ssh", "http-server", "https-server"]

  metadata = {
    user-data = module.container-server.cloud_config # 👈
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos.self_link
    }
  }

  network_interface {
    subnetwork         = var.subnet_name
    subnetwork_project = var.project

    access_config {
      // Ephemeral IP
    }
  }
}

```

# Terraform

## Inputs

| Name           | Description                                                          | Type     | Default | Required |
| -------------- | -------------------------------------------------------------------- | -------- | ------- | :------: |
| cloud_dns_zone | Cloud DNS zone name.                                                 | `string` | n/a     |   yes    |
| domain         | The domain where the app will be hosted.                             | `string` | n/a     |   yes    |
| email          | Email address used when registering certificates with Let's Encrypt. | `string` | n/a     |   yes    |
| project        | The ID of the project in which to provision resources.               | `string` | n/a     |   yes    |
| region         | Google Cloud region where the instance will be created.              | `string` | n/a     |   yes    |
| subnet_name    | The name of the subnet where the instance will be created.           | `string` | n/a     |   yes    |

## Outputs

| Name                  | Description |
| --------------------- | ----------- |
| docker_compose_config | n/a         |
