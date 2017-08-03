#####################################################################
# This file contains general configuration settings,
#   which will be checked into source control.
#####################################################################

variable "default_tags" {
  type = "map"
  default = {
    owner = "<YOUR_ID>"
    project = "<YOUR_PROJECT>"
    purpose = "<YOUR_PURPOSE>"
    environment = "<YOUR_DEV_ENV_NAME>"
  }

  /*
  # A resource may use this directly by
  tags = ${var.default_tags}"

  # Or a resource may use these tags with additional tags by
  tags = "${merge(var.default_tags, map(
    "name", "fruit",
    "flavor", "lemon"
  ))}"
  */
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default = "<YOUR_ID>"
}

variable "public_key_path" {
  description = <<DESCRIPTION
    Path to the SSH public key to be used for authentication.  Ensure this
    keypair is added to your local SSH agent so provisioners can connect.
DESCRIPTION
  default = "~/.ssh/id_rsa.pub"
}

variable "aws_access_key_id" {
  description = "AWS access key id"
  default     = "<YOUR_AWS_ACCESS_KEY_ID>"
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  default     = "<YOUR_AWS_SECRET_ACCESS_KEY>"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-west-1"
}

# Centos 7 HVM 64 images can be found here:
#   https://aws.amazon.com/marketplace/fulfillment?productId=b7ee8a69-ee97-4a49-9e68-afaee216db2e
# Each region has an individual ID for this Cento7 image
# us-east-1: US East (N. Virginia)
# us-east-2: US East (Ohio)
# us-west-1: US West (N. California)
# us-west-2: US West (Oregon)
variable "aws_amis" {
  default = {
    us-east-1 = "ami-46c1b650"
    us-east-2 = "ami-18f8df7d"
    us-west-1 = "ami-f5d7f195"
    us-west-2 = "ami-f4533694"
  }
}
