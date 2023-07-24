variable "api_token" {}

variable "org_name" {}

variable "base_url" {}

variable "password_minimum_length" {
  default = 15
}

variable "password_min_lowercase" {
  default = 1
}

variable "password_min_number" {
  default = 1
}

variable "password_min_symbol" {
  default = 1
}

variable "password_min_age_minutes" {
  default = 60
}

variable "password_exclude_username" {
  default = true
}

variable "password_exclude_first_name" {
  default = true
}

variable "password_exclude_last_name" {
  default = true
}

variable "password_dictionary_lookup" {
  default = true
}

variable "password_max_age_days" {
  default = 90
}

variable "password_expire_warn_days" {
  default = 15
}

variable "password_history_count" {
  default = 24
}

variable "password_max_lockout_attempts" {
  default = 5
}

variable "password_auto_unlock_minutes" {
  default = 30
}

variable "password_show_lockout_failures" {
  default = true
}

variable "email_recovery" {
  default = "ACTIVE"
}

variable "sms_recovery" {
  default = "ACTIVE"
}

variable "question_recovery" {
  default = "ACTIVE"
}

variable "report_suspicious_activity_enabled" {
  default = true
}

variable "send_email_for_factor_enrollment_enabled" {
  default = true
}

variable "send_email_for_factor_reset_enabled" {
  default = true
}

variable "send_email_for_new_device_enabled" {
  default = true
}

variable "send_email_for_password_changed_enabled" {
  default = true
}