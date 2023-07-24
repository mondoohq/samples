resource "okta_policy_password_default" "default" {
  password_min_length            = var.password_minimum_length
  password_min_lowercase         = var.password_min_lowercase
  password_min_number            = var.password_min_number
  password_min_symbol            = var.password_min_symbol
  password_min_age_minutes       = var.password_min_age_minutes
  password_exclude_username      = var.password_exclude_username
  password_exclude_first_name    = var.password_exclude_first_name
  password_exclude_last_name     = var.password_exclude_last_name
  password_dictionary_lookup     = var.password_dictionary_lookup
  password_max_age_days          = var.password_max_age_days
  password_expire_warn_days      = var.password_expire_warn_days
  password_history_count         = var.password_history_count
  password_max_lockout_attempts  = var.password_max_lockout_attempts
  password_auto_unlock_minutes   = var.password_auto_unlock_minutes
  password_show_lockout_failures = var.password_show_lockout_failures
  email_recovery                 = var.email_recovery
  sms_recovery                   = var.sms_recovery
  question_recovery              = var.question_recovery
}