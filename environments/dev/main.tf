provider "google" {
  credentials = "${file("~/.gcloud/k8s-hard-way.json")}"
  project = "k8s-hard-way-222321"
  region = "europe-west1"
  zone = "europe-west1-b"
}

# Virtual Private Cloud Network
# -----------------------------
resource "google_compute_network" "k8s-hard-way-net" {
  name = "k8s-hard-way-net"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "kube-subnet" {
  name = "kube-subnet"
  region = "europe-west1"
  network = "${google_compute_network.k8s-hard-way-net.name}"
  ip_cidr_range = "10.240.0.0/24"
}

# Firewall Rules
# --------------
# Allows all internal communications
resource "google_compute_firewall" "kube-fw-allow-internal" {
  name = "kube-fw-allow-internal"
  network = "${google_compute_network.k8s-hard-way-net.name}"

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["10.240.0.0/24", "10.200.0.0/16"]
}

# Allows ssh, icmp and https from outside
resource "google_compute_firewall" "kube-fw-allow-external" {
  name = "kube-fw-allow-external"
  network = "${google_compute_network.k8s-hard-way-net.name}"

  allow {
    protocol = "tcp"
    ports = [22, 6443]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}