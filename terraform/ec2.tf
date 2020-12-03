# EC2 instances

# EC2 keypair
resource "aws_key_pair" "airgap_keypair" {
  key_name   = "airgap-keypair"
  public_key = "${file("${var.ssh_key_name}.pub")}"
}

# EC2 instance attached to igw
resource "aws_instance" "staging_instance" {
  ami                         = "${var.image_id}"
  instance_type               = "${var.ec2_instance_type}"
  key_name                    = "airgap-keypair"
  vpc_security_group_ids      = [ "${aws_security_group.allow_ssh.id}" ]
  subnet_id                   = "${aws_subnet.public.id}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.ag_profile.id}"


  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 500
    },
  ]

  tags = {
    Name       = "${var.cluster_id}-staging-node",
    owner      = "${var.owner}",
    expiration = "${var.expiration}"
  }

  connection {
    host        = "${aws_instance.staging_instance.public_ip}"
    type        = "ssh"
    user        = "${var.image_username}"
    private_key = "${file("${var.ssh_key_name}.pem")}"
  }
  
  provisioner "file" {
    source      = "${var.ssh_key_name}.pem"
    destination = "~/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    script = "scripts/setup.sh"
  }

}

# EC2 Instance without Internet Access
resource "aws_instance" "bootstrap_instance" {
  ami                         = "${var.image_id}"
  instance_type               = "${var.ec2_instance_type}"
  key_name                    = "airgap-keypair"
  vpc_security_group_ids      = [ "${aws_security_group.allow_ssh.id}" ]
  subnet_id                   = "${aws_subnet.private.id}"
  associate_public_ip_address = false
  iam_instance_profile        = "${aws_iam_instance_profile.ag_profile.id}"

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 1000
    },
  ]

  tags = {
    Name       = "${var.cluster_id}-bootstrap-node",
    owner      = "${var.owner}",
    expiration = "${var.expiration}"
  }
}

locals {
  "user_at_system" = "${format("%s@%s", var.image_username, aws_instance.bootstrap_instance.private_ip)}"
}

resource "null_resource" "preflight" {
  
  connection {
    host = "${aws_instance.staging_instance.public_ip}"
    type = "ssh"
    user = "${var.image_username}"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 ~/.ssh/id_rsa",
      "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ~/.ssh/id_rsa ${local.user_at_system}:~/.ssh/id_rsa",
      "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r /home/centos/bootstrap ${local.user_at_system}:/home/centos/bootstrap",
      "curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip",
      "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null awscliv2.zip ${local.user_at_system}:.",
      "curl -OL ${var.dkp_archive}",
      "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /home/centos/${var.dkp_archive} ${local.user_at_system}:/home/centos/${var.dkp_archive}",
      "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${local.user_at_system} chmod 600 ~/.ssh/id_rsa",
      "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${local.user_at_system} sudo yum install ./bootstrap/*.rpm -y",
      "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${local.user_at_system} tar -xvf ${var.dkp_archive}",
      "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${local.user_at_system} sudo systemctl enable --now docker",
      "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${local.user_at_system} sudo usermod -aG docker centos",
      "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${local.user_at_system} unzip awscliv2.zip",
      "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${local.user_at_system} sudo aws/install"
    ]
  }
}

#"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${local.user_at_system} docker load < konvoy_v1.6.0-rc.2/images/docker.io_registry\:2.tar",
#"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${local.user_at_system} docker run -d -p 5000:5000 --restart=always --name registry registry:2"
#"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${local.user_at_system} sudo setenforce 0"

