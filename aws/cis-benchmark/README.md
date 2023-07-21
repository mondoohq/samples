# Performing CIS AWS Foundations Benchmark with cnspec

## Overview

This guide provides an example on how to execute a CIS Amazon Web Services Foundations Benchmark on your AWS account using the `cnspec`. The CIS (Center for Internet Security) Amazon Web Services Foundations Benchmark provides a set of security configuration best practices for AWS. Performing this benchmark will help ensure that your AWS environment is secure and adheres to the principles of least privilege and defense in depth.

## Pre-requisites

- You should have the `cnspec` installed. You can follow the [installation instructions](https://github.com/mondoohq/cnspec#installation) to set it up.
- You need an AWS account and the necessary permissions to manage your resources.
- The AWS CLI should be installed and configured with your credentials.

## Instructions

To perform the CIS AWS Foundations Benchmark, you can use the following command with `cnspec`:

```bash
cnspec scan aws --policy mondoo-cis-aws-foundations-benchmark
```

This command instructs `cnspec` to scan your AWS environment using the CIS Amazon Web Services Foundations Benchmark, discovering all the resources and security issues in your account.

## Results

`cnspec` generates a report detailing the security status of your AWS account according to the CIS AWS Foundations Benchmark. The report will identify any security vulnerabilities or misconfigurations and recommend potential areas for improvement.

![cnspec running a CIS AWS Foundation Benchmark](./aws-account-cis-benchmark.gif)

## Troubleshoot

- **`cnspec` issues**: Make sure that `cnspec` is installed correctly. If you have trouble running `cnspec`, try updating to the latest version or re-installing the tool.
- **AWS CLI**: Ensure that AWS CLI is installed and configured correctly. Verify that you are using the correct AWS credentials. If you encounter permission errors, check your AWS IAM role and permissions.
- **Benchmark execution issues**: If the benchmark does not execute as expected, ensure that you have the necessary permissions to access all resources in your AWS account.

If you encounter a problem that is not addressed in this guide, feel free to raise an issue in this GitHub repository. For more complex or ongoing issues, consider participating in our [Github discussions](https://github.com/orgs/mondoohq/discussions) page. We're here to help!
