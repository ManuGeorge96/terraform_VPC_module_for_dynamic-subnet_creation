output "VPC_ID" {
  value = aws_vpc.vpc-requestor.id
}
output "Public-Subnet-IDs" {
  value = aws_subnet.requestor-Public.*.id
}
output "Private-Subnet-IDs" {
  value = aws_subnet.requestor-Private.*.id
}
