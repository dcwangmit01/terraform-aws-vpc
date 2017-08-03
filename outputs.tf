output "bastion_eip_address" {
  value = "${aws_eip.bastion.public_ip}"
}

output "bastion_private_address" {
  value = "${aws_instance.bastion.private_ip}"
}

output "private1_private_address" {
  value = "${aws_instance.private1.private_ip}"
}
