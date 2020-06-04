variable "aws_access_key_id" {}
variable "aws_secret_key" {}
variable "aws_session_token" {}

provider "aws" {
  version    = "~> 2.4"
  region     = "${var.aws_region}"
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_key}"
  token      = "${var.aws_session_token}"
}

provider "random" {
  version = "~> 2.1"
}

resource "random_id" "id" {
  byte_length = 2
}

locals {
  cluster_name = "${var.cluster_name_random_string ? format("%s-%s", var.cluster_name, random_id.id.hex) : var.cluster_name}"

  jumpbox_keypair_name    = "${local.cluster_name}-jumpbox"
  instance_jumpbox_name   = "${local.cluster_name}-jumpbox"
  instance_bootstrap_name = "${local.cluster_name}-bootstrap"

  repo_port     = 80
  registry_port = 5000

  cache_packages = "${length(var.cache_packages) != 0 ? var.cache_packages : [
    "chrony",
    "nvme-cli",
    "yum-plugin-versionlock",
    "libseccomp",
    "containerd.io-${var.containerd_version}",
    "container-selinux",
    "nfs-utils",
    "kubectl-${var.kubernetes_version}-0",
    "kubelet-${var.kubernetes_version}-0",
    "kubernetes-cni",
    "kubeadm-${var.kubernetes_version}-0",
    "cri-tools",
    "nvidia-container-runtime",
    "libnvidia-container-tools",
    "libnvidia-container1",
    "nvidia-container-toolkit",
  ]}"
}

resource "aws_key_pair" "jumpbox" {
  key_name   = "${local.jumpbox_keypair_name}"
  public_key = "${file(var.ssh_public_key_file)}"
}

resource "random_password" "registry_pass" {
  length = 24
}

data "template_file" "jumpbox_userdata" {
  template = "${file("${path.module}/jumpbox_user_data.tmpl")}"

  vars = {
    cache_packages = "${join(" ", local.cache_packages)}"
    registry_port  = "${local.registry_port}"
    registry_pass  = "${random_password.registry_pass.result}"
    registry_user  = "${var.registry_user}"
    repo_port      = "${local.repo_port}"
  }
}

resource "aws_instance" "jumpbox" {
  ami                         = "${var.jumpbox_ami_id}"
  associate_public_ip_address = true
  instance_type               = "${var.jumpbox_instance_type}"
  key_name                    = "${aws_key_pair.jumpbox.key_name}"
  subnet_id                   = "${aws_subnet.public.id}"
  vpc_security_group_ids      = ["${aws_security_group.jumpbox.id}"]
  user_data                   = "${data.template_file.jumpbox_userdata.rendered}"

  root_block_device {
    volume_size           = "${var.jumpbox_root_volume_size}"
    volume_type           = "${var.jumpbox_root_volume_type}"
    delete_on_termination = true
  }

  tags = "${merge(
    var.aws_tags,
    map(
      "Name", "${local.instance_jumpbox_name}",
    )
  )}"
}

data "template_file" "cluster_userdata" {
  template = "${file("${path.module}/cluster_user_data.tmpl")}"

  vars = {
    repo_url = "http://${aws_instance.jumpbox.private_ip}:${local.repo_port}/"
  }
}

resource "aws_instance" "bootstrap" {
  ami = "${var.cluster_ami_id}"

  instance_type          = "${var.bootstrap_instance_type}"
  key_name               = "${aws_key_pair.jumpbox.key_name}"
  subnet_id              = "${aws_subnet.private.id}"
  vpc_security_group_ids = ["${aws_security_group.cluster.id}"]
  user_data              = "${data.template_file.cluster_userdata.rendered}"

  root_block_device {
    volume_size           = "${var.bootstrap_root_volume_size}"
    volume_type           = "${var.bootstrap_root_volume_type}"
    delete_on_termination = true
  }

  tags = "${merge(
    var.aws_tags,
      map(
        "Name", "${local.instance_bootstrap_name}",
      )
    )}"
}

output "jumpbox_public_ip" {
  value = "${aws_instance.jumpbox.public_ip}"
}

output "cluster_name" {
  value = "${local.cluster_name}"
}

output "ssh_command" {
  value = "ssh -i ${var.ssh_private_key_file} -J ${var.ssh_user}@${aws_instance.jumpbox.public_ip} ${var.ssh_user}@${aws_instance.bootstrap.private_ip}"
}
