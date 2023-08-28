# Scan a GCP Project against the CIS GCP Foundations Benchmark using cnspec

## Overview

This guide provides an example on how to scan a GCP project against the CIS Google Cloud Foundations Benchmark using `cnspec`. The CIS (Center for Internet Security) Google Cloud Foundations Benchmark provides a set of security configuration best practices for Google Cloud. Performing this benchmark will help ensure that your GCP project is secure and adheres to the principles of least privilege and defense in depth.

## Pre-requisites

- You should have the `cnspec` installed. You can follow the [installation instructions](https://github.com/mondoohq/cnspec#installation) to set it up.
- You need an Google Cloud service account account and the necessary permissions.
- The Google Cloud SDK installed and configured with access to the project you wish to scan.

## Instructions

To scan a Google Cloud project against the CIS Google Cloud Foundations Benchmark:

```bash
cnspec scan gcp --project-id <project-id> --policy mondoo-cis-gcp-foundations-benchmark
```

This command instructs `cnspec` to scan a Google Cloud project using the CIS Google Cloud Foundations Benchmark, discovering all the resources and security issues in your account.

## Results

`cnspec` generates a report detailing the security status of your GCP project according to the CIS Google Cloud Foundations Benchmark. The report will identify any security vulnerabilities or misconfigurations and recommend potential areas for improvement.

![cnspec running a CIS Google Cloud Foundation Benchmark](./gcp-project-cis-benchmark.gif)

## Troubleshoot

- **`cnspec` issues**: Make sure that `cnspec` is installed correctly. If you have trouble running `cnspec`, try updating to the latest version or re-installing the tool.
- **gcloud SDK CLI**: Ensure that `gcloud` CLI is [installed and configured](https://cloud.google.com/sdk/docs/install-sdk) correctly. Verify that you are using the correct account or service account credentials. If you encounter permission errors, check your IAM role and permissions.
- **Benchmark execution issues**: If the benchmark does not execute as expected, ensure that you have the necessary permissions to access all resources in your Google Cloud project.

If you encounter a problem that is not addressed in this guide, feel free to raise an issue in this GitHub repository. For more complex or ongoing issues, consider participating in our [Github discussions](https://github.com/orgs/mondoohq/discussions) page. We're here to help!
