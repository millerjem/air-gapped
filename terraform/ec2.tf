# EC2 instances

# EC2 keypair
resource "aws_key_pair" "airgap_keypair" {
  key_name_prefix   = "airgap-keypair"
  public_key = "${file("${var.ssh_key_name}.pub")}"
}

# EC2 instance attached to igw
resource "aws_instance" "staging_instance" {
  ami                         = "${var.image_id}"
  instance_type               = "${var.ec2_instance_type}"
  key_name                    = "${aws_key_pair.airgap_keypair.key_name}"
  vpc_security_group_ids      = [ "${aws_security_group.allow_ssh.id}" ]
  subnet_id                   = "${aws_subnet.public.id}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.ag_profile.id}"


  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 1500
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
  key_name                    = "${aws_key_pair.airgap_keypair.key_name}"
#  vpc_security_group_ids      = [ "${aws_security_group.allow_ssh.id}","${aws_security_group.allow_all.id}" ]
  vpc_security_group_ids      = [ "${aws_security_group.allow_all.id}" ]
  subnet_id                   = "${aws_subnet.private.id}"
  associate_public_ip_address = false
  iam_instance_profile        = "${aws_iam_instance_profile.ag_profile.id}"

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 1500
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
      "curl -OL https://downloads.mesosphere.io/konvoy/${var.dkp_archive}",
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

resource "aws_network_interface" "lb" {
  subnet_id = "${"${aws_subnet.private.id}"}"
  security_groups = [ "${aws_security_group.allow_all.id}" ]
  #private_ips = ["10.0.2.20","10.0.2.30","10.0.2.31","10.0.2.33","10.0.2.34","10.0.2.35","10.0.2.36","10.0.2.37","10.0.2.38","10.0.2.39","10.0.2.40","10.0.2.41","10.0.2.42","10.0.2.43","10.0.2.44","10.0.2.45","10.0.2.25"]
  private_ips_count = 10
  
  #attachment {
  #  instance = "${element(aws_instance.cp_instance.*.id,0)}"
  #  device_index = 0
  #}
}

# EC2 Instance without Internet Access
resource "aws_instance" "cp_instance" {
  ami                         = "${var.image_id}"
  count                       = 0 
  instance_type               = "${var.ec2_instance_type}"
  key_name                    = "${aws_key_pair.airgap_keypair.key_name}"
  #vpc_security_group_ids      = [ "${aws_security_group.allow_all.id}" ]
  #subnet_id                   = "${aws_subnet.private.id}"
  #associate_public_ip_address = false
  
  iam_instance_profile        = "${aws_iam_instance_profile.ag_profile.id}"

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 160
    }
  ]

  network_interface {
    device_index = 0
    network_interface_id = "${aws_network_interface.lb.id}"
  }

  tags = {
    Name       = "${var.cluster_id}-cp-${count.index}-node",
    owner      = "${var.owner}",
    expiration = "${var.expiration}"
  }
}

resource "aws_network_interface" "internal-lb" {
  subnet_id = "${"${aws_subnet.private.id}"}"
  security_groups = [ "${aws_security_group.allow_all.id}" ]
  private_ips_count = 10
}


resource "aws_eip" "lb" {
  vpc = true
  associate_with_private_ip = "false"
  # associate_with_private_ip = "10.0.2.20"
}

resource "aws_eip_association" "eip_assoc" {
  network_interface_id = "${aws_network_interface.lb.id}"
  allocation_id       = "${aws_eip.lb.id}"
  allow_reassociation = true
  # private_ip_address  = "10.0.2.20"
}

resource "aws_instance" "worker_instance" {
  ami                         = "${var.image_id}"
  count                       = 0
  instance_type               = "${var.ec2_instance_type}"
  key_name                    = "${aws_key_pair.airgap_keypair.key_name}"
  # vpc_security_group_ids      = [ "${aws_security_group.allow_all.id}" ]
  #subnet_id                   = "${aws_subnet.private.id}"
  #associate_public_ip_address = false
  iam_instance_profile        = "${aws_iam_instance_profile.ag_profile.id}"

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 160
    }
  ]

  network_interface {
    #associate_public_ip_address = false
    device_index = 0
    network_interface_id = "${"aws_network_interface.internal-lb.id"}"
    #network_interface = "${format("aws_network_interface.internal-lb-%d.id", count.index)}"
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "55"
    volume_type = "gp2"
    delete_on_termination = true
  }

  ebs_block_device {
    device_name = "/dev/sdc"
    volume_size = "55"
    volume_type = "gp2"
    delete_on_termination = true

  }

  ebs_block_device {
    device_name = "/dev/sdd"
    volume_size = "55"
    volume_type = "gp2"
    delete_on_termination = true
  }

  ebs_block_device {
    device_name = "/dev/sde"
    volume_size = "55"
    volume_type = "gp2"
    delete_on_termination = true
  }

  tags = {
    Name       = "${var.cluster_id}-worker-${count.index}-node",
    owner      = "${var.owner}",
    expiration = "${var.expiration}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /mnt/disks/data-vol-01",
      "sudo mkdir -p /mnt/disks/data-vol-02",
      "sudo mkdir -p /mnt/disks/data-vol-03",
      "sudo mkdir -p /mnt/disks/data-vol-04",
      "sudo mkfs -t xfs /dev/nvme1n1",
      "sudo mkfs -t xfs /dev/nvme2n1",
      "sudo mkfs -t xfs /dev/nvme3n1",
      "sudo mkfs -t xfs /dev/nvme4n1",
      "echo '/dev/nvme1n1 /mnt/disks/data-vol-01 xfs defaults 0 2' | sudo tee -a /etc/fstab > /dev/null",
      "echo '/dev/nvme2n1 /mnt/disks/data-vol-02 xfs defaults 0 2' | sudo tee -a /etc/fstab > /dev/null",
      "echo '/dev/nvme3n1 /mnt/disks/data-vol-03 xfs defaults 0 2' | sudo tee -a /etc/fstab > /dev/null",
      "echo '/dev/nvme4n1 /mnt/disks/data-vol-04 xfs defaults 0 2' | sudo tee -a /etc/fstab > /dev/null",    
      "sudo mount -a",
    ]
    connection {
      user = "${var.image_username}"
      type = "ssh"
      bastion_host = "${aws_instance.staging_instance.public_ip}"
      bastion_user = "${var.image_username}"
    }
  }
}

# resource "aws_network_interface_attachment" "attached" {
#   instance_id = "${element(aws_instance.worker_instance.*.id, count.index)}"
#   network_interface_id = "${element(aws_network_interface.internal-lb.*.id, count.index)}"
#   device_index = 0
# }
