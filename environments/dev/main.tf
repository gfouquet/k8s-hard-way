provider "google" {
  credentials = "${file("~/.gcloud/k8s-hard-way.json")}"
  project = "k8s-hard-way-222321"
  region = "${var.region}"
  zone = "${var.zone}"
}

# NETWORKING
# ==========
# Virtual Private Cloud Network
# -----------------------------
resource "google_compute_network" "k8s-hard-way-net" {
  name = "k8s-hard-way-net"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "kube-subnet" {
  name = "kube-subnet"
  region = "${var.region}"
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

# K8s public IP
resource "google_compute_address" "kube-public-ip" {
  name = "kube-public-ip"
  region = "${var.region}"
}

# COMPUTE
# =======
# K8s contollers
# --------------
resource "google_compute_instance" "kube-master" {
  count = 3
  name = "kube-master-${count.index}"
  machine_type = "n1-standard-1"
  can_ip_forward = true
  tags = ["k8s-hard-way", "kube-master"]

  boot_disk {
    initialize_params {
      size = 200
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network_ip = "10.240.0.1${count.index}"
    subnetwork = "${google_compute_subnetwork.kube-subnet.name}"
  }

  service_account {
    scopes = [
      "compute-rw",
      "storage-ro",
      "service-management",
      "service-control",
      "logging-write",
      "monitoring"
    ]
  }
}