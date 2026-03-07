locals {
  prod_network_configs    = yamldecode(file("../playbooks/vars/network_configs.yml"))
  staging_network_configs = yamldecode(file("../.vagrant/network_configs.yml"))
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.18"
    }
  }
  backend "s3" {
    bucket  = "0d6e4079e367-homelab-cm"
    key     = "public-dns/terraform.tfstate"
    region  = "us-east-1"
    profile = "main-opentofu"
  }

  # renovate: datasource=github-releases packageName=opentofu/opentofu versioning=hashicorp
  required_version = "~> 1.11.0"
}

provider "aws" {
  region  = "us-east-1"
  profile = "main-opentofu"
}

resource "aws_iam_user" "ddns" {
  name = "ddns"
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

resource "aws_iam_user_policy" "ddns" {
  name = "IAMUserDdns"
  user = aws_iam_user.ddns.name

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
              "gw.${local.prod_network_configs.homelab_network_domain}",
              "gw.${local.staging_network_configs.homelab_network_domain}",
            ]
          }
        }
      }
    ]
  })
}

resource "aws_route53_record" "vpn" {
  for_each = toset([
    local.prod_network_configs.homelab_network_domain,
    local.staging_network_configs.homelab_network_domain,
  ])
  zone_id = data.aws_route53_zone.homelab.arn
  name    = "vpn.${each.value}"
  type    = "CNAME"
  ttl     = 300
  records = ["gw.${each.value}"]
}

resource "aws_iam_access_key" "ddns" {
  user = aws_iam_user.ddns.name
}

resource "aws_iam_user" "cert_manager" {
  name = "cert-manager"
}

resource "aws_iam_user_policy" "cert_manager" {
  name = "IAMUserCertManager"
  user = aws_iam_user.cert_manager.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:GetChange"]
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets",
        ]
        Resource = "arn:aws:route53:::hostedzone/${data.aws_route53_zone.homelab.id}"
        Condition = {
          "ForAllValues:StringEquals" = {
            "route53:ChangeResourceRecordSetsRecordTypes" = ["TXT"]
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ListHostedZonesByName"]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_access_key" "cert_manager" {
  user = aws_iam_user.cert_manager.name
}
