output "homelab_zone_id" {
  value = data.aws_route53_zone.homelab.zone_id
}

output "ddns_access_key" {
  value = aws_iam_access_key.ddns.id
}

# access using 'tofu output -raw ddns_secret_key'
output "ddns_secret_key" {
  value     = aws_iam_access_key.ddns.secret
  sensitive = true
}

output "cert_manager_access_key" {
  value = aws_iam_access_key.cert_manager.id
}

output "cert_manager_secret_key" {
  value     = aws_iam_access_key.cert_manager.secret
  sensitive = true
}
