locals {
  prod_network_configs    = yamldecode(file("../playbooks/vars/network_configs.yml"))
  staging_network_configs = yamldecode(file("../.vagrant/network_configs.yml"))
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.98"
    }
  }
  backend "s3" {
    bucket  = "0d6e4079e367-homelab-cm"
    key     = "public-dns/terraform.tfstate"
    region  = "us-east-1"
    profile = "main-opentofu"
  }

  # renovate: datasource=github-releases packageName=opentofu/opentofu versioning=hashicorp
  required_version = "~> 1.10.0"
}

provider "aws" {
  region  = "us-east-1"
  profile = "main-opentofu"
}

resource "aws_iam_user" "vpn_homelab_ddns" {
  name = "vpn-homelab-ddns"
}

data "aws_route53_zone" "homelab" {
  name = join(".",
    slice(
      split(
        ".",
        local.prod_network_configs.homelab_network_domain
      ),
      1,
      3,
    )
  )
}

resource "aws_iam_user_policy" "vpn_homelab_ddns" {
  name = "IAMUserVpnHomelabDdns"
  user = aws_iam_user.vpn_homelab_ddns.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
        ]
        Resource = data.aws_route53_zone.homelab.arn
        Condition = {
          "ForAllValues:StringEquals" = {
            "route53:ChangeResourceRecordSetsNormalizedRecordNames" = [
              "vpn.${local.prod_network_configs.homelab_network_domain}",
              "vpn.${local.staging_network_configs.homelab_network_domain}",
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_access_key" "vpn_homelab_ddns" {
  user = aws_iam_user.vpn_homelab_ddns.name
}
