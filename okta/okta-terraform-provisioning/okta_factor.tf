// "fido_u2f", "fido_webauthn", "google_otp", "okta_call", "okta_otp", "okta_password", "okta_push", "okta_question", "okta_sms", "okta_email", "rsa_token", "symantec_vip", "yubikey_token", or "hotp".

resource "okta_factor" "google_otp" {
  provider_id = "google_otp"
  active      = true
}

resource "okta_factor" "okta_password" {
  provider_id = "okta_password"
  active      = true
}

resource "okta_factor" "okta_otp" {
  provider_id = "okta_otp"
  active      = true
}

resource "okta_factor" "okta_push" {
  provider_id = "okta_push"
  active      = true
}

resource "okta_policy_mfa_default" "classic_default" {
  is_oie = false

  okta_password = {
    enroll = "REQUIRED"
  }

  okta_otp = {
    enroll = "REQUIRED"
  }

  okta_push = {
    enroll = "REQUIRED"
  }
}