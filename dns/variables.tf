
variable "cloudflare_ip_range" {
  description = "IPv4 addresses for cloudflare. Grabbed via API GET to https://api.cloudflare.com/client/v4/ips at 01/17/2023"
  type        = list(string)
  default = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22",
    "2400:cb00::/32",
    "2606:4700::/32",
    "2803:f800::/32",
    "2405:b500::/32",
    "2405:8100::/32",
    "2a06:98c0::/29",
    "2c0f:f248::/32"
  ]
}

variable "cloudflare_zone_id" {
  description = "Zone ID for Cloudflare Domain"
}

variable "cloudflare_domain" {
  description = "Domain name to be used for accessing the website"
}

variable "cloudflare_api_token" {
  description = "token used for cloudflare. defined in terraform cloud"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "The account ID for Cloudflare"
  type        = string
}