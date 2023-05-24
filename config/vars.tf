#
# Variables for TKC Demo
#

variable "thunder_username" {
  description = "Username to use for API access to Thunder node"
  type = string
  default = "admin"
}

variable "thunder_password" {
  description = "Password for Username for API access to Thunder node"
  type = string
  default = "a10"
}

variable "thunder_ip_address" {
  description = "IP address of MGMT port on Thunder node"
  type = string
  default = "<Management_IP>"
}

variable "thunder_instance_id" {
  description = "Instance ID of vThunder in AWS"
  type        = string
  default     = "<instance_id>"
}

variable "thunder_vip" {
  description = "IP address of VIP on Thunder node"
  type = string
  default = "10.0.11.230" #per vpc.tf
}

variable "prov_config_path" {
  description = "Path to a Kubernetes config file"
  type = string
  default = "~/.kube/config"
}

variable "thunder_glm_token" {
  description = "License Token from A10 GLM System"
  type = string
  default = "<A10_License_Token>"
}

variable "demo_namespace" {
  description = "The Namespace string for K8s deployment"
  type = string
  default = "demo"
}
