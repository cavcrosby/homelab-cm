output "homelab_zone_id" {
  value = data.aws_route53_zone.homelab.zone_id
}

output "vpn_homelab_ddns_access_key" {
  value = aws_iam_access_key.vpn_homelab_ddns.id
}

# access using 'tofu output -raw vpn_homelab_ddns_secret_key'
output "vpn_homelab_ddns_secret_key" {
  value     = aws_iam_access_key.vpn_homelab_ddns.secret
  sensitive = true
}
