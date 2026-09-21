variable "project" {
    default = "roboshop"
}

variable "environment" {
    default = "dev"
}

variable "zone_name" {
  type        = string
  default     = "mahidevops.fun"
  description = "description"
}

variable "zone_id" {
  type        = string
  default     = "Z0333367NHGBMIBI3F"
  description = "description"
}

variable "sonar" {
  default = false
}