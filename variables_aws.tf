#------------| AWS Secrets|---------------

variable "aws_access" {
  description = "AWS Access token"
  type        = string
  sensitive   = true
}

variable "aws_secret" {
  description = "AWS Secret token"
  type        = string
  sensitive   = true
}

#------------| AWS 53 DNS|---------------
variable "aws_region" {
  description = "Регион aws"
  type        = string
  default     = "us-east-1"
}

variable "zone_name" {
  description = "Зона 53 :D"
  type        = string
  default     = "devops.rebrain.srwx.net."
}

variable "dns_type" {
  description = "Тип DNS записи"
  type        = string
  default     = "A"
}

variable "ttl" {
  description = "007: не время умирать"
  type        = number
  default     = "300"
}
