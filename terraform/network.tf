locals {
  vpc_name          = "${local.cluster_name}-vpc"
  gw_name           = "${local.cluster_name}-gateway"
  elb_name          = "${local.cluster_name}-cp"
  public_name       = "${local.vpc_name}-public"
  private_name      = "${local.vpc_name}-public"
  sg_cluster_name   = "${local.cluster_name}-cluster"
  sg_jumpbox_name   = "${local.cluster_name}-jump"
  public_route_name = "${local.vpc_name}-public-route"
}

resource "aws_vpc" "airgap" {
  cidr_block = "10.0.0.0/16"

  tags = "${merge(
    var.aws_tags,
    map(
      "Name", local.vpc_name,
    )
  )}"
}

resource "aws_internet_gateway" "internet" {
  vpc_id = "${aws_vpc.airgap.id}"

  tags = "${merge(
    var.aws_tags,
    map(
      "Name", local.gw_name,
    )
  )}"
}

resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.airgap.id}"
  cidr_block = "10.0.10.0/24"

  map_public_ip_on_launch = true

  tags = "${merge(
    var.aws_tags,
    map(
      "Name", local.public_name,
    )
  )}"
}

resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.airgap.id}"
  cidr_block = "10.0.0.0/24"

  tags = "${merge(
    var.aws_tags,
    map(
      "Name", local.private_name,
    )
  )}"
}

resource "aws_route_table" "public-route" {
  vpc_id = "${aws_vpc.airgap.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet.id}"
  }

  tags = "${merge(
    var.aws_tags,
    map(
      "Name", local.public_route_name,
    )
  )}"
}

resource "aws_route_table_association" "public-subnet-association" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public-route.id}"
}

resource "aws_security_group" "jumpbox" {
  name   = "${local.sg_jumpbox_name}"
  vpc_id = "${aws_vpc.airgap.id}"

  tags = "${merge(
    var.aws_tags,
    map(
      "Name", local.sg_jumpbox_name,
    )
  )}"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = "${var.admin_cidr_blocks}"
  }

  ingress {
    protocol    = "tcp"
    from_port   = "${local.repo_port}"
    to_port     = "${local.repo_port}"
    cidr_blocks = ["${aws_subnet.private.cidr_block}"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = "${local.registry_port}"
    to_port     = "${local.registry_port}"
    cidr_blocks = ["${aws_subnet.private.cidr_block}"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cluster" {
  name   = "${local.sg_cluster_name}"
  vpc_id = "${aws_vpc.airgap.id}"

  tags = "${merge(
    var.aws_tags,
    map(
      "Name", local.sg_cluster_name,
    )
  )}"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["${aws_subnet.public.cidr_block}"]
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${aws_subnet.private.cidr_block}"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${aws_subnet.public.cidr_block}"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${aws_subnet.private.cidr_block}"]
  }
}
