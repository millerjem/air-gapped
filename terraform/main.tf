# Locals
locals {
  az = "${format("%s%s", var.region_id, "a")}"
}

# Provider
provider "aws" {
  version = "v2.70.0"
  profile = "${var.profile_id}"
  region  = "${var.region_id}"
}

# Vpc
resource "aws_vpc" "airgap_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_id}-vpc"
  }
}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.airgap_vpc.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "${local.az}"

  tags = {
    Name = "${var.cluster_id}-public-subnet"
  }
}

# Igw
resource "aws_internet_gateway" "airgap_vpc_igw" {
  vpc_id = "${aws_vpc.airgap_vpc.id}"

  tags = {
    Name = "${var.cluster_id}-igw"
  }
}

# Public route table
resource "aws_route_table" "airgap_vpc_region_public" {
    vpc_id = "${aws_vpc.airgap_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.airgap_vpc_igw.id}"
    }

    tags = {
        Name = "${var.cluster_id}-public-rt"
    }
}

# Public route table associations
resource "aws_route_table_association" "airgap_vpc_region_public" {
    subnet_id = "${aws_subnet.public.id}"
    route_table_id = "${aws_route_table.airgap_vpc_region_public.id}"
}

# Private subnet
resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.airgap_vpc.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "${local.az}"

  tags = {
    Name = "${var.cluster_id}-private-subnet"
    #,
    #kubernetes.io/cluster = "govcloud",
    #kubernetes.io/cluster/CLUSTER_NAME = "owned",
    #kubernetes.io/role/internal-elb = "1"
  }
}

# Private subnet
#resource "aws_subnet" "private-lb" {
#  vpc_id     = "${aws_vpc.airgap_vpc.id}"
#  cidr_block = "10.0.3.0/24"
#  availability_zone = "${local.az}"

#  tags = {
#    Name = "${var.cluster_id}-private-lb-subnet"
#  }
#}

# Private routing table
resource "aws_route_table" "airgap_vpc_region_private" {
    vpc_id = "${aws_vpc.airgap_vpc.id}"

    tags = {
        Name = "${var.cluster_id}-private-rt"
    }
}

# Private routing table association
resource "aws_route_table_association" "airgap_vpc_region_private" {
    subnet_id = "${aws_subnet.private.id}"
    route_table_id = "${aws_route_table.airgap_vpc_region_private.id}"
}

# Private routing table association
#resource "aws_route_table_association" "airgap_vpc_region_private-lb" {
#    subnet_id = "${aws_subnet.private-lb.id}"
#    route_table_id = "${aws_route_table.airgap_vpc_region_private.id}"
#}

# Output
output "connection_details" {
  value = <<EOF

    Use the following to connect to the bootstrap node and enjoy the ride...

    ssh -J ${var.image_username}@${aws_instance.staging_instance.public_ip} ${var.image_username}@${aws_instance.bootstrap_instance.private_ip}

  EOF
}

output "public_ip" {
  description = "List of public IP addresses assigned to the instances, if applicable"
  value       = "${aws_instance.staging_instance.*.public_ip}"
}

output "private_ip" {
  description = "List of private IP addresses assigned to the instances, if applicable"
  value       = "${aws_instance.bootstrap_instance.*.private_ip}"
}

output "instance_profile" {
  description = "Assume instance profile"
  value       = "${aws_iam_instance_profile.ag_profile.arn}"
}

output "vpc_id" {
  description = "AWS VPC ID"
  value       = "${aws_vpc.airgap_vpc.id}"
}

output "subnet_private_id" {
  description = "AWS Private Subnet ID"
  value       = "${aws_subnet.private.id}"
}
