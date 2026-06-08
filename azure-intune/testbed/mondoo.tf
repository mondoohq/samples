# -----------------------------------------------------------------------------
# Mondoo Space and Registration Token (Optional)
# Only created if MONDOO_API_TOKEN is set and mondoo_api_token var is provided
# -----------------------------------------------------------------------------

# Create a Mondoo Space in the specified organization
resource "mondoo_space" "intune_demo" {
  count  = var.mondoo_api_token != "" ? 1 : 0
  name   = var.mondoo_space_name
  org_id = var.mondoo_org_id

  # Allow time for integrations to clean up before destroying
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Waiting 15 seconds before destroying space...' && sleep 15"
  }
}

# Generate a registration token for Windows VMs
resource "mondoo_registration_token" "vm_token" {
  count         = var.mondoo_api_token != "" ? 1 : 0
  description   = "Registration token for Windows VMs"
  space_id      = mondoo_space.intune_demo[0].id
  no_expiration = true

  depends_on = [mondoo_space.intune_demo]
}

