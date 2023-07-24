data "okta_network_zone" "BlockedIpZoneDefault" {
  name = "BlockedIpZoneDefault"
}

data "okta_network_zone" "LegacyIpZone" {
  name = "LegacyIpZone"
}

resource "okta_network_zone" "ip_network_zone_blocked" {
  name     = "WhiteListedIPs"
  type     = "IP"
  gateways = ["98.24.172.148-98.24.172.148"]
  proxies  = ["98.24.172.148-98.24.172.148"]
}

resource "okta_network_zone" "blockedips" {
  name     = "BlockedIpZone"
  type     = "IP"
  usage    = "BLOCKLIST"
  gateways = ["2.58.56.101-2.58.56.101", "23.128.248.39-23.128.248.39"]
}

resource "okta_threat_insight_settings" "blocked_ip" {
  action           = "block"
  network_excludes = [okta_network_zone.ip_network_zone_blocked.id]
}

output "BlockedIpZone" {
  value = data.okta_network_zone.BlockedIpZoneDefault.id
}