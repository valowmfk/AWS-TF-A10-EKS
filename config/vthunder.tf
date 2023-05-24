#
#  vThunder configs for TKC demo
#
#  John D. Allen
#  Global Solutions Architect - Cloud, IOT, & Automation
#  A10 Networks, Inc.
#  Apache v2.0 License applies.
#  June, 2021
#

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    thunder = {
      source = "a10networks/thunder"
      version = ">=1.2.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.18.1"
    }
  }
}

provider "thunder" {
  address  = var.thunder_ip_address
  username = var.thunder_username
  # password = var.thunder_instance_id
  password = var.thunder_password
}

resource "thunder_hostname" "hostname" {
  value = "<hostname>"
}

resource "thunder_ip_dns_primary" "dns1" {
  ip_v4_addr = "8.8.8.8"
}

resource "thunder_ip_route_rib" "default" {
  ip_dest_addr = "0.0.0.0"
  ip_mask = "/0"
  ip_nexthop_ipv4 {
    ip_next_hop = "10.0.11.1"
  }
}

resource "thunder_ip_route_rib" "private" {
  ip_dest_addr = "10.0.102.0"
  ip_mask = "/24"
  ip_nexthop_ipv4 {
    ip_next_hop = "10.0.101.1"
  }
}
resource "thunder_slb_template_virtual_server" "bw-control" {
  name = "bw-control"
  conn_limit = 20
  conn_rate_limit = 20
}

resource "thunder_virtual_server" "ws-vip" {
    depends_on = [
      thunder_slb_template_virtual_server.bw-control
   ]
  name = "ws-vip"
  ip_address = var.thunder_vip
  port_list {
    port_number = 80
    protocol = "http"
  }
}

resource "thunder_glm" "license-glm" {
  depends_on = [
    thunder_virtual_server.ws-vip
  ]
  appliance_name = "<name>"
  token = var.thunder_glm_token
  use_mgmt_port = 1
  enable_requests = 1
  allocate_bandwidth = 1000 #Update for your license type (in Mbps)
  interval = 1 
}

resource "thunder_glm_send" "get-license" {
  depends_on = [
    thunder_glm.license-glm
  ] 
  license_request = 1
}
#
# Configure ethernet interfaces and name/description
#
resource "thunder_interface_ethernet" "eth1" {
  ifnum  = 1
  name   = "Eth1_Servers_Public_Inside"
  action = "enable"
  ip {
    address_list {
      ipv4_address = "10.0.11.16"
      ipv4_netmask = "/24"
    }
  }
}
resource "thunder_interface_ethernet" "eth2" {
  ifnum  = 2
  name   = "Eth2_Servers_VIP_Private_Outside"
  action = "enable"
  ip {
    address_list {
      ipv4_address = "10.0.101.133"
      ipv4_netmask = "/24"
    }
  }
}