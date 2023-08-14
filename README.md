# Security Scanning with cnspec, cnquery, and Mondoo Platform <!-- omit from toc -->

![samples light-mode illustration](.github/social/preview_light.jpg#gh-light-mode-only)
![samples dark-mode illustration](.github/social/preview_dark.jpg#gh-dark-mode-only)

Welcome to our comprehensive security scanning repository! In our ongoing effort to empower the highest standards of security, we've gathered a variety of examples and guides to help you conduct thorough security audits on your resources using `cnspec`, `cnquery`, and the Mondoo Platform. Our examples, ranging from AWS services to GitHub repositories, are structured with a clear overview, prerequisites, step-by-step instructions, expected results, and troubleshooting tips. We trust these will serve as a beneficial starting point for your own security scanning needs.

- [What are cnspec, cnquery, and Mondoo Platform?](#what-are-cnspec-cnquery-and-mondoo-platform)
- [AWS](#aws)
  - [Performing CIS AWS Foundations Benchmark with cnspec](#performing-cis-aws-foundations-benchmark-with-cnspec)
  - [Checking Public Exposure of AWS S3 Buckets with cnspec](#checking-public-exposure-of-aws-s3-buckets-with-cnspec)
  - [Verifying MFA Status for AWS IAM Users](#verifying-mfa-status-for-aws-iam-users)
  - [Scanning an AWS EC2 Instance with cnspec using EC2 Instance Connect](#scanning-an-aws-ec2-instance-with-cnspec-using-ec2-instance-connect)
  - [Playing with AWS EC2 Instances](#playing-with-aws-ec2-instances)
- [GitHub](#github)
  - [Performing CIS GitHub Supply Chain Benchmark with cnspec](#performing-cis-github-supply-chain-benchmark-with-cnspec)
- [Hack Lab](#hack-lab)
  - [Demonstrating Container Escape in Kubernetes](#demonstrating-container-escape-in-kubernetes)
- [Contributing](#contributing)

## What are cnspec, cnquery, and Mondoo Platform?

`cnspec` is a powerful command-line tool designed for conducting security benchmark tests against various systems, providing insights into potential vulnerabilities and areas of improvement.

`cnquery` is another versatile command-line tool that facilitates advanced querying against your infrastructure data, allowing you to understand and manage your infrastructure more effectively.

The Mondoo Platform is a cloud-native, security and compliance automation platform that enables businesses to secure their infrastructure continuously and at scale.

Together, these provide a comprehensive approach to managing and maintaining the security posture of your systems.

## AWS

### Performing CIS AWS Foundations Benchmark with cnspec

This guide provides an example on how to execute a CIS Amazon Web Services Foundations Benchmark on your AWS account using the `cnspec`. The CIS (Center for Internet Security) Amazon Web Services Foundations Benchmark provides a set of security configuration best practices for AWS. Performing this benchmark will help ensure that your AWS environment is secure and adheres to the principles of least privilege and defense in depth.

![cnspec running a CIS AWS Foundation Benchmark](./aws/cis-benchmark/aws-account-cis-benchmark.gif)

- [Instructions](./aws/cis-benchmark/)

### Checking Public Exposure of AWS S3 Buckets with cnspec

This example uses `cnspec` to check for publicly exposed AWS S3 buckets within your AWS account. Publicly exposed buckets can lead to unauthorized access or data breaches, and it's critical to ensure they are secure.

![cnspec running a AWS S3 bucket scan](./aws/public-s3/aws-public-s3.gif)

- [Instructions](./aws/public-s3/)

### Verifying MFA Status for AWS IAM Users

This guide demonstrates how to verify that all AWS IAM users have Multi-Factor Authentication (MFA) enabled. Ensuring MFA is crucial in securing your AWS resources as it offers an additional layer of protection by requiring users to provide at least two forms of identification.

![cnspec running a AWS IAM scan](./aws/iam-mfa/aws-iam-mfa.gif)

- [Instructions](./aws/iam-mfa/)

### Scanning an AWS EC2 Instance with cnspec using EC2 Instance Connect

This guide walks you through conducting a security scan on an AWS EC2 instance utilizing `cnspec` and EC2 Instance Connect. EC2 Instance Connect provides a secure and auditable means to connect to your instances, thereby eliminating the necessity to have an open public SSH port.

![cnspec running a AWS IAM scan](./aws/ec2-instance-connect/aws-ec2-instance.gif)

- [Instructions](./aws/ec2-instance-connect/)

## GitHub

### Performing CIS GitHub Supply Chain Benchmark with cnspec

This guide provides an example on how to execute the CIS (Center for Internet Security) GitHub Benchmark on GitHub repositories and organizations using the `cnspec` and Mondoo platform. These benchmarks offer a standardized set of procedures to assess the security posture of GitHub repositories and organizations, helping to identify vulnerabilities or potential areas for security enhancements.

![cnspec running a GitHub organization scan](./github/cis-supply-chain/github-supply-chain.gif)

- [Instructions](./github/cis-supply-chain/)

## Hack Lab

The Hack Lab is a collection of vulnerable systems that can be used to learn and practice security concepts. The Hack Lab is a great way to get started with security scanning and learn how to use `cnspec` and `cnquery` to identify and resolve security issues.

### Demonstrating Container Escape in Kubernetes

This houses demonstration scenarios showcasing container escapes in Kubernetes environments, particularly in AKS (Azure Kubernetes Service), EKS (Amazon Elastic Kubernetes Service) and GKE (Google Kontainer Engine). These scenarios can serve as engaging demonstrations using Mondoo.

- [Instructions](./hacklab/container-escape/)

## Playing with AWS EC2 Instances

The AWS EC2 Instances is a terraform to deploy hardend and not hardend Windows as well as Linux systems.

- [Instructions](./aws/ec2-instance/)

## Contributing

We welcome contributions! Feel free to submit pull requests for new examples or improvements to existing ones. If you encounter any issues or have questions, please open an issue in this repository or join our [Github discussions](https://github.com/orgs/mondoohq/discussions) page. We're here to help!
