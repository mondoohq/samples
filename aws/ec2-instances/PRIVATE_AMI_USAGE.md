# Private AMI Usage Guide

This document explains how to use the new private AMI functionality in this Terraform configuration.

## Overview

The configuration now supports creating EC2 instances from private AMIs. This is useful when you have custom AMIs created in your AWS account or shared with you from another account.

## Configuration Variables

The following variables control private AMI instances:

### Required Variables

- **`private_ami_id`**: The AMI ID of your private image
  - Example: `ami-0abcdef1234567890`
  - Default: `""` (empty, must be set in terraform.tfvars)

- **`private_ami_owner`**: The AWS account ID that owns the AMI
  - Example: `123456789012`
  - Default: `""` (empty, must be set in terraform.tfvars)

### Optional Variables

- **`private_ami_name`**: Name identifier for the instance (used in resource naming)
  - Default: `private`
  - This will create instances named like `mondoo-private-<random_id>`

- **`private_ami_ssh_user`**: SSH username for connecting to the instance
  - Default: `ec2-user`
  - Common alternatives: `ubuntu`, `admin`, `rocky`, etc.

- **`private_ami_instance_type`**: EC2 instance type
  - Default: `t2.micro`

### Instance Creation Flags

- **`create_private_ami`**: Create a basic instance from the private AMI
  - Default: `false`

- **`create_private_ami_cnspec`**: Create an instance with cnspec/Mondoo installed
  - Default: `false`

## Usage Examples

### Example 1: Basic Private AMI Instance

Add to your `terraform.tfvars`:

```hcl
# Enable private AMI instance
create_private_ami = true

# Configure the AMI
private_ami_id    = "ami-0abcdef1234567890"
private_ami_owner = "123456789012"

# Optional: Customize naming and SSH
private_ami_name     = "myapp"
private_ami_ssh_user = "ec2-user"
```

### Example 2: Private AMI with cnspec

```hcl
# Enable cnspec-enabled instance
create_private_ami_cnspec = true

# Configure the AMI
private_ami_id    = "ami-0abcdef1234567890"
private_ami_owner = "123456789012"

# Required for cnspec
mondoo_registration_token = "your-mondoo-token-here"

# Optional customization
private_ami_name          = "secure-app"
private_ami_ssh_user      = "ubuntu"
private_ami_instance_type = "t2.small"
```

### Example 3: Multiple Private AMIs

If you need to deploy from different private AMIs, you can modify the variables for each deployment or create separate terraform workspaces.

```hcl
# First deployment
private_ami_id    = "ami-0abcdef1234567890"
private_ami_owner = "123456789012"
private_ami_name  = "app1"
create_private_ami = true

# After applying, change values for next deployment
# terraform apply -var="private_ami_id=ami-xxxxxxxx" -var="private_ami_name=app2"
```

## Outputs

After applying, you'll get SSH connection strings:

```bash
# View outputs
terraform output private_ami
terraform output private_ami_cnspec

# Example output:
# ssh -o StrictHostKeyChecking=no -i ~/.ssh/your-key ec2-user@54.123.45.67
```

## Architecture

The private AMI instances use:
- **Security Group**: The same Linux security group as other Linux instances
- **VPC**: The main VPC created by this configuration
- **Subnet**: The first public subnet
- **User Data**: 
  - Basic instance: No user data
  - cnspec instance: Installs and configures Mondoo cnspec

## Data Source

The configuration uses the `aws_ami` data source to lookup your private AMI:

```hcl
data "aws_ami" "private_ami" {
  most_recent = true

  filter {
    name   = "image-id"
    values = [var.private_ami_id]
  }

  owners = [var.private_ami_owner]
}
```

This ensures:
- The AMI exists and is accessible
- The AMI belongs to the specified owner account
- Validation happens during `terraform plan`

## Troubleshooting

### AMI Not Found

**Error**: `InvalidAMIID.NotFound` or `InvalidAMIID.Unavailable`

**Solution**: 
1. Verify the AMI ID is correct
2. Ensure the AMI is in the same region as your deployment
3. Check that the AMI is shared with your AWS account (if it's from another account)

### Permission Denied

**Error**: `You are not authorized to perform this operation`

**Solution**:
1. Verify the `private_ami_owner` account ID is correct
2. If using a shared AMI, ensure it's been shared with your account
3. Check your AWS credentials have permission to launch instances

### Wrong SSH User

**Error**: SSH connection fails or permission denied

**Solution**:
1. Check the AMI documentation for the correct SSH user
2. Update `private_ami_ssh_user` variable accordingly
3. Common users by OS:
   - Amazon Linux: `ec2-user`
   - Ubuntu: `ubuntu`
   - Debian: `admin`
   - RHEL/CentOS: `ec2-user`
   - Rocky Linux: `rocky`

## Integration with Existing Configuration

The private AMI instances integrate seamlessly with the existing infrastructure:

- ✅ Use the same VPC and subnets
- ✅ Use the same Linux security groups
- ✅ Support the same naming conventions
- ✅ Support cnspec/Mondoo integration
- ✅ Generate SSH connection strings in outputs

## Next Steps

1. Update your `terraform.tfvars` with your AMI details
2. Run `terraform plan` to preview changes
3. Run `terraform apply` to create the instances
4. Use the output SSH commands to connect

For more information, see the main [README.md](README.md).

