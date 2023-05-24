variable "aws_access_key" {
  description = "AWS access key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
}

variable "region" {
  description = "The aws region. https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html"
  type        = string
  default     = "us-west-2"
}

variable "availability_zones_count" {
  description = "The number of AZs."
  type        = number
  default     = 2
}

variable "project" {
  description = "A10 AWS Cloud Demo"
  # description = "Name of the project deployment."
  type = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_bits" {
  description = "The number of subnet bits for the CIDR. For example, specifying a value 8 for this parameter will create a CIDR with a mask of /24."
  type        = number
  default     = 8
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    "Project"     = "CloudDemo"
    "Environment" = "Demo"
    "Owner"       = "A10 Networks"
  }
}
variable "azs" {
  description = "The number of AZs."
  type        = number
  default     = 2
}
variable "subnet" {
  type = map(string)
  default = {
    "frontend" = "A10 Cloud Frontend subnet"
    "backend"  = "A10 Cloud Backend subnet"
    "mgmt"     = "A10 Cloud Management subnet"
    "public"   = "A10 Cloud Public subnet"
  }
}
variable "mapPublicIP" {
  default = true
}
variable "cidr" {
  type = map(string)
  default = {
    "vpc"     = "10.0.0.0/8"
    "mgmt1"   = "10.0.251.0/24"
    "mgmt2"   = "10.0.252.0/24"
  }
}
