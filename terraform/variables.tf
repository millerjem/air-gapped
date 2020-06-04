variable "aws_region" {
  description = "AWS region where to deploy the cluster"
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "The name of the provisioned cluster"
  default     = "air-gapped"
}

variable "cluster_name_random_string" {
  description = "Add a random string to the cluster name"
  default     = true
}

variable "admin_cidr_blocks" {
  type        = list(string)
  description = "Admin CIDR blocks that can access the cluster from outside"
  default     = ["0.0.0.0/0"]
}

variable "bootstrap_ips" {
  type        = list(string)
  description = "Control plane ip addresses"
  default     = ["10.1.0.20"]
}

variable "ssh_private_key_file" {
  description = "Path to the SSH private key"
  default     = "./id_mesosphere"
}

variable "ssh_public_key_file" {
  description = "Path to the SSH public key"
  default     = "./id_mesosphere.pub"
}

variable "ssh_user" {
  description = "The SSH user that should be used for accessing the nodes over SSH"
  default     = "centos"
}

variable "aws_tags" {
  description = "Add custom tags to all resources"
  type        = map(string)
  default     = {}
}

variable "jumpbox_instance_type" {
  description = "Instance type for jumpbox"
  default     = "t3.micro"
}

variable "jumpbox_root_volume_size" {
  description = "Jumpbox root volume size"
  default     = "80"
}

variable "jumpbox_root_volume_type" {
  description = "Jumpbox root volume type"
  default     = ""
}

variable "jumpbox_ami_id" {
  description = "AMI to use for jumpbox"
  default     = "ami-01ed306a12b7d1c96"
}

variable "bootstrap_instance_type" {
  description = "Instance type for control plane instances"
  default     = "m5.xlarge"
}

variable "bootstrap_instances" {
  description = "Number of control plane instances to launch"
  default     = 3
}

variable "bootstrap_root_volume_size" {
  description = "Control Plane root volume size"
  default     = "80"
}

variable "bootstrap_root_volume_type" {
  description = "Control Plane root volume type"
  default     = ""
}

variable "cluster_ami_id" {
  description = "AMI to use for bootstrap instances"
  default     = "ami-01ed306a12b7d1c96"
}

variable "cache_packages" {
  description = "Packages to cache in the jumpbox repo"
  type        = list(string)
  default     = []
}

variable "containerd_version" {
  description = "Version of Containerd to cache by default"
  default     = "1.2.6"
}

variable "kubernetes_version" {
  description = "Version of kubernets to cache by default"
  default     = "1.16.3"
}

variable "registry_user" {
  description = "User name for the docker registry"
  default     = "ishmael"
}
