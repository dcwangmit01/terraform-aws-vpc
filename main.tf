
#####################################################################
# Specify the provider and access details

provider "aws" {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  region = "${var.aws_region}"
}

#####################################################################
# Create a VPC to hold our subnets which hold instances
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  tags = "${var.default_tags}"
}

#####################################################################
# Setup the gateways

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
  tags = "${var.default_tags}"
}

resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "default" {
  allocation_id = "${aws_eip.nat_gateway.id}"
  subnet_id     = "${aws_subnet.public.id}"

  depends_on = ["aws_internet_gateway.default"]
}

#####################################################################
# Setup the route tables

# The route table for the public network goes through the internet gateway without NAT
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
  tags = "${var.default_tags}"
}

# The route table for the private network goes through the internet gateway with NAT
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.default.id}"
  }
  tags = "${var.default_tags}"
}

#####################################################################
# Associate the route tables to their respective subnets

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

#####################################################################
# Define the public and private subnets where our instances will live

# This subnet is for machines that need to be publicly accessible.
resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = false
  tags = "${var.default_tags}"
}
# This subnet is for machines that should not be publicly accessible.
resource "aws_subnet" "private" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  tags = "${var.default_tags}"
}

#####################################################################
# Define security groups for the public and private subnets

# This security gorup is for the public subnet
resource "aws_security_group" "public" {
  name        = "public"
  description = "This security group restricts access for public"
  vpc_id      = "${aws_vpc.default.id}"

  # Ping from anywwhere
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # enable all access from all subnets within the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.default_tags}"
}

# This security gorup is for the private subnet, which is not publically accessible
resource "aws_security_group" "private" {
  name        = "private"
  description = "This security group restricts access for private"
  vpc_id      = "${aws_vpc.default.id}"

  # enable all access from all subnets within the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.default_tags}"
}

#####################################################################
# Create the keypair which will be installed on all hosts

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
  # tags: This aws_route resource does not allow the setting of tags
}

#####################################################################
# Create the bastion host (aka Jumpbox), which will be used to access machines
#   on the private subnet

resource "aws_eip" "bastion" {
  instance = "${aws_instance.bastion.id}"
  vpc      = true
}

resource "aws_instance" "bastion" {

  # The connection block tells our provisioner how to communicate with the
  # resource (instance)
  connection {
    # The default username for our AMI
    user = "centos"

    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  # Set the key to be provisioned on the machine
  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow public access
  vpc_security_group_ids = ["${aws_security_group.public.id}"]

  # Launch this bastion host into the public subnet
  subnet_id = "${aws_subnet.public.id}"

  associate_public_ip_address = true

  # Run a remote provisioner on the instance after creating it.
  provisioner "remote-exec" {
    inline = [
      "hostname",
    ]
  }

  # Set identifiying tags
  tags = "${merge(var.default_tags, map(
    "Name", "bastion",
  ))}"
}

resource "aws_instance" "private1" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "centos"

    # The connection will use the local SSH agent for authentication.

    # Since this machine is on a private network, it must be reached thorough
    # the bastion host for verification.
    bastion_host = "${aws_eip.bastion.public_ip}"
    bastion_user = "centos"
  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  # Set the key to be provisioned on the machine
  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow only private access
  vpc_security_group_ids = ["${aws_security_group.private.id}"]

  # Launch this private host into the private subnet
  subnet_id = "${aws_subnet.private.id}"

  # Run a remote provisioner on the instance after creating it.
  provisioner "remote-exec" {
    inline = [
      "hostname",
    ]
  }

  # Set identifiying tags
  tags = "${merge(var.default_tags, map(
    "Name", "private1",
  ))}"
}
