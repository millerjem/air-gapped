# AWS service endpoints

# EC2 endpoint
resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = "${aws_vpc.airgap_vpc.id}"
  service_name      = "com.amazonaws.${var.region_id}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.allow_ssh.id}",
  ]

  subnet_ids = [
    "${aws_subnet.private.id}"
  ]

  private_dns_enabled = true
}

# ELB endpoint
resource "aws_vpc_endpoint" "elb" {
  vpc_id            = "${aws_vpc.airgap_vpc.id}"
  service_name      = "com.amazonaws.${var.region_id}.elasticloadbalancing"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.allow_ssh.id}",
  ]

  subnet_ids = [
    "${aws_subnet.private.id}"
  ]

  private_dns_enabled = true
}

# STS endpoint
resource "aws_vpc_endpoint" "sts" {
  vpc_id            = "${aws_vpc.airgap_vpc.id}"
  service_name      = "com.amazonaws.${var.region_id}.sts"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.allow_ssh.id}",
  ]

  subnet_ids = [
    "${aws_subnet.private.id}"
  ]

  private_dns_enabled = true
}

# S3 endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = "${aws_vpc.airgap_vpc.id}"
  service_name      = "com.amazonaws.${var.region_id}.s3"
}

#S3 endpoint routing table association
resource "aws_vpc_endpoint_route_table_association" "route_table_association" {
  route_table_id  = "${aws_route_table.airgap_vpc_region_private.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}

