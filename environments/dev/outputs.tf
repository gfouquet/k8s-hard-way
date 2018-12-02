output "kube_masters" {
  value = {
    names = ["${google_compute_instance.kube-master.*.name}"]
    public_ips = ["${google_compute_instance.kube-master.*.network_interface.0.access_config.0.assigned_nat_ip}"]
    private_ips = ["${google_compute_instance.kube-master.*.network_interface.0.network_ip}"]
  }
}
output "kube_workers" {
  value = {
    names = ["${google_compute_instance.kube-worker.*.name}"]
    public_ips = ["${google_compute_instance.kube-worker.*.network_interface.0.access_config.0.assigned_nat_ip}"]
    private_ips = ["${google_compute_instance.kube-worker.*.network_interface.0.network_ip}"]
  }
}
output "kube_public_ip" {
  value = "${google_compute_address.kube-public-ip.address}"
}