output "public_subnet_id_1" {
  value = aws_subnet.public_1.id
}
output "public_subnet_id_2" {
  value = aws_subnet.public_2.id
}
output "private_subnet_id_1" {
  value = aws_subnet.private_1.id
}
output "private_subnet_id_2" {
  value = aws_subnet.private_2.id
}
output "instance_id" {
  value = aws_instance.ssm_instance.id
}

output "instance_public_ip" {
  value = aws_instance.ssm_instance.public_ip
}
