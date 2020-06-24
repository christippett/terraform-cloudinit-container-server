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

resource "digitalocean_droplet" "portainer" {
  name   = "portainer"
  image  = "docker-18-04"
  region = "lon1"
  size   = "s-1vcpu-1gb"

  user_data = module.docker-server.cloud_config
}

resource "digitalocean_floating_ip" "portainer" {
  region = digitalocean_droplet.portainer.region
}

resource "digitalocean_floating_ip_assignment" "portainer" {
  ip_address = digitalocean_floating_ip.portainer.ip_address
  droplet_id = digitalocean_droplet.portainer.id
}

/* DNS ---------------------------------------------------------------------- */

resource "digitalocean_domain" "default" {
  name       = "portainer.${var.domain}"
  ip_address = digitalocean_droplet.portainer.ipv4_address
}

/* Firewall ----------------------------------------------------------------- */

resource "digitalocean_firewall" "portainer" {
  name = "portainer-ingress"

  droplet_ids = [digitalocean_droplet.portainer.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

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
