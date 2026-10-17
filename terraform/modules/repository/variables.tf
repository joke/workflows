variable "name" {
  type        = string
  description = "Repository name, without the owner."
}

variable "description" {
  type        = string
  description = "Repository description."
}

variable "topics" {
  type        = list(string)
  description = "Repository topics."
  default     = []
}

variable "homepage" {
  type        = string
  description = "Repository homepage URL. Empty when there is none."
  default     = ""
}

variable "required_checks" {
  type        = list(string)
  description = "Status check names required before merging to main. Empty skips the required checks for the repository."
  default     = []
}
