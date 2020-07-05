# Docker Compose — Google Cloud Platform

Deploys a Docker Compose file to a Compute Engine instance.

## Features

- Built on top of Google's [Container Optimized OS](https://cloud.google.com/container-optimized-os)
- Enables the [Google Cloud logging driver](https://docs.docker.com/config/containers/logging/gcplogs/) for improved container observability in Stackdriver
- Uses a supplemental cloud-init config to format and mount a persistent disk for storing Let's Encrypt certificates that persist beyond the life of the instance
- Creates a static IP and associates it with a Cloud DNS record
- Enables Traefik's [monitoring dashboard](https://docs.traefik.io/operations/dashboard/) and API (available at `<your-domain>:9000`)

## Usage

```hcl
resource "google_compute_instance" "app_server" {
  name         = "app-server"
  project      = var.project
  zone         = "${var.region}-a"
  machine_type = "e2-small"
  tags         = ["ssh", "http-server", "https-server"]

  metadata = {
    user-data = module.container-server.cloud_config # 👈
  }

  service_account {
    email  = google_service_account.default.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
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
      nat_ip = google_compute_address.static.address
    }
  }

  scheduling {
    automatic_restart = true
  }

  allow_stopping_for_update = true

  lifecycle {
    ignore_changes = [attached_disk]
  }
}

```

# Terraform

## Inputs

| Name               | Description                                                          | Type     | Default | Required |
| ------------------ | -------------------------------------------------------------------- | -------- | ------- | :------: |
| cloud_dns_zone     | Cloud DNS zone name.                                                 | `string` | n/a     |   yes    |
| domain             | The domain where the app will be hosted.                             | `string` | n/a     |   yes    |
| email              | Email address used when registering certificates with Let's Encrypt. | `string` | n/a     |   yes    |
| project            | The ID of the project in which to provision resources.               | `string` | n/a     |   yes    |
| region             | Google Cloud region where the instance will be created.              | `string` | n/a     |   yes    |
| subnet_name        | The name of the subnet where the instance will be created.           | `string` | n/a     |   yes    |
| portainer_password | Password to log into Portainer. Must be hashed using `bcrypt`.       | `string` | n/a     |   yes    |

## Outputs

| Name                  | Description |
| --------------------- | ----------- |
| docker_compose_config | n/a         |
