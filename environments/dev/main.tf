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
# K8s masters
# -----------
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


    access_config {
      # creates ephemeral external ip
    }
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

  metadata {
    sshKeys = "${var.ssh_user}:${file(var.ssh_public_key)}"
  }
}

# K8s workers
# -----------
resource "google_compute_instance" "kube-worker" {
  count = 3
  name = "kube-worker-${count.index}"
  machine_type = "n1-standard-1"
  can_ip_forward = true
  tags = ["k8s-hard-way", "kube-worker"]

  boot_disk {
    initialize_params {
      size = 200
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network_ip = "10.240.0.2${count.index}"
    subnetwork = "${google_compute_subnetwork.kube-subnet.name}"

    access_config {
      # creates ephemeral external ip
    }
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

  metadata {
    pod-cidr = "10.200.${count.index}.0/24"
    sshKeys = "${var.ssh_user}:${file(var.ssh_public_key)}"
  }
}

# CONTROL PLANE
# =============
# K8s frontend load balancer
# --------------------------
resource "google_compute_http_health_check" "kube-health-check" {
  name = "kubernetes"
  host = "kubernetes.default.svc.cluster.local"
  request_path = "/healthz"
}

resource "google_compute_firewall" "k8s-hard-way-allow-health-check" {
  name = "k8s-hard-way-allow-health-check"
  network = "${google_compute_network.k8s-hard-way-net.name}"
  source_ranges = [ "209.85.152.0/22","209.85.204.0/22","35.191.0.0/16" ]
  allow {
    protocol = "tcp"
  }
}

resource "google_compute_target_pool" "kube-target-pool" {
  name = "kube-target-pool"
  health_checks = [ "${google_compute_http_health_check.kube-health-check.name}" ]
  instances = [
    "${var.zone}/${google_compute_instance.kube-master.0.name}",
    "${var.zone}/${google_compute_instance.kube-master.1.name}",
    "${var.zone}/${google_compute_instance.kube-master.2.name}"
  ]
}

resource "google_compute_forwarding_rule" "kube-forwarding-rule" {
  name = "kube-forwarding-rule"
  ip_address = "${google_compute_address.kube-public-ip.address}"
  port_range = "6443"
  region = "${var.region}"
  target = "${google_compute_target_pool.kube-target-pool.self_link}"
}