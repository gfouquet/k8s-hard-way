variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-b"
}

variable "ssh_user" {
  default = "kube"
}

variable "ssh_public_key" {
  default = "~/.ssh/id_rsa.pub"
}