# Verifying MFA Status for AWS IAM Users

## Overview

This guide demonstrates how to verify that all AWS IAM users have Multi-Factor Authentication (MFA) enabled. Ensuring MFA is crucial in securing your AWS resources as it offers an additional layer of protection by requiring users to provide at least two forms of identification.

## Pre-requisites

- You should have the `cnspec` installed. You can follow the [installation instructions](https://github.com/mondoohq/cnspec#installation) to set it up.
- You need an AWS account and the necessary permissions to manage your resources.
- The AWS CLI should be installed and configured with your credentials.

## Instructions

To perform the MFA check, you can use the following command with `cnspec`:

```bash
cnspec scan aws --discover iam-users
```

This command lists all IAM users and checks each user for enabled MFA devices. The result will be a list of usernames with their MFA status.

## Results

The output will be a list of IAM usernames with a check on whether MFA is enabled:

![cnspec running a CIS AWS Foundation Benchmark](./aws-iam-mfa.gif)

## Troubleshoot

- **`cnspec` issues**: Make sure that `cnspec` is installed correctly. If you have trouble running `cnspec`, try updating to the latest version or re-installing the tool.
- **AWS CLI**: Ensure that AWS CLI is installed and configured correctly. Verify that you are using the correct AWS credentials. If you encounter permission errors, check your AWS IAM role and permissions.
- **Policy execution issues**: If the policy does not execute as expected, ensure that you have the necessary permissions to access all resources in your AWS account.

Should you encounter a problem that is not addressed in this guide, feel free to open an issue in this Github repository. For ongoing issues or broader discussions, we invite you to join us over at our [Github discussions](https://github.com/orgs/mondoohq/discussions) page. We're here to help!
