# Security Groups

# Data
locals {
  sg_name = "${format("%s_%s_%s", var.cluster_id, "ssh", "sg")}"
}

# Allow ssh
resource "aws_security_group" "allow_ssh" {
  name        = "${local.sg_name}"
  description = "Allow SSH inbound connections"
  vpc_id      = "${aws_vpc.airgap_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.sg_name}"
  }
}
