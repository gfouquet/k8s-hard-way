output "kube_masters_public_ips" {
  value = ["${google_compute_instance.kube-master.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}
output "kube_workers_public_ips" {
  value = ["${google_compute_instance.kube-worker.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}