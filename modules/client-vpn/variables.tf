variable "region" {
  default     = "us-east-1"
  description = "Region to create the Client VPN in"
}

variable "private_subnets" {
  description = "CIDRs for private subnets, currently expects exactly 2"
}

variable "vpc_id" {
  description = "VPC to connect the client vpn to"
}

variable "vpn_cidr" {
  default     = "17.10.0.0/16"
  description = "The CIDR block to assign to clients of the VPN"
}

variable "vpn_server_cert_arn" {
  default     = "arn:aws:acm:eu-west-2:xxxxxxxx:certificate/xxxxx"
  description = "The Server Certificate to use for configuring the VPN"
}

variable "vpn_client_cert_arn" {
  default     = "arn:aws:acm:eu-west-2:xxxxxxxxx:certificate/xxxxx"
  description = "The Client Certificate to use to authorize with the server"
}

variable "opvn_filepath" {
  default     = "config.ovpn"
  description = "The OVPN file for OpenVPN Client, `cert` and `key` attributes needs to be added and they should container the keys used in client cert Client VPN was created with."
}
