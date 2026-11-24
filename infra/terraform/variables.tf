variable "aws_region" {
  type        = string
  description = "Región del Learner Lab (Academy suele ser us-east-1)."
  default     = "us-east-1"
}

variable "project" {
  type        = string
  description = "Prefijo de los repositorios ECR."
  default     = "doy0101-tienda"
}
