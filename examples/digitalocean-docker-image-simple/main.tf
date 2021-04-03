module "container-server" {
  source = "../.."

  domain = "app.${var.domain}"
  email  = var.email

  container = {
    image = "nginxdemos/hello"
  }
}

/* Instance ----------------------------------------------------------------- */

resource "digitalocean_droplet" "app" {
  name   = "app"
  image  = "docker-18-04"
  region = "lon1"
  size   = "s-1vcpu-1gb"

  user_data = module.container-server.cloud_config
}

resource "digitalocean_floating_ip" "app" {
  region = digitalocean_droplet.app.region
}

resource "digitalocean_floating_ip_assignment" "app" {
  ip_address = digitalocean_floating_ip.app.ip_address
  droplet_id = digitalocean_droplet.app.id
}

/* DNS ---------------------------------------------------------------------- */

resource "digitalocean_domain" "default" {
  name       = "app.${var.domain}"
  ip_address = digitalocean_floating_ip.app.ip_address
}

/* Firewall ----------------------------------------------------------------- */

resource "digitalocean_firewall" "app" {
  name = "app-ingress"

  droplet_ids = [digitalocean_droplet.app.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
}
