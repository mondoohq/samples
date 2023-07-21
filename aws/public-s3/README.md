# Checking Public Exposure of AWS S3 Buckets with cnspec

## Overview

This example uses `cnspec` to check for publicly exposed AWS S3 buckets within your AWS account. Publicly exposed buckets can lead to unauthorized access or data breaches, and it's critical to ensure they are secure.

## Pre-requisites

- You should have an AWS account and the necessary credentials (Access Key ID and Secret Access Key) available.
- Install cnspec following the instructions provided at the installation page of the cnspec Github repository.

## Instructions

To scan all your AWS S3 buckets, use the `cnspec` with the scan option, as follows:

```bash
cnspec scan aws --discover s3-buckets
```

This command will initiate a scan across your AWS S3 buckets and report any that are publicly exposed.

## Results

After running the `cnspec` command, you see a report printed to your console. The report will list all the S3 buckets, their results.

![cnspec running a AWS S3 bucket scan](aws-public-s3.gif)

## Troubleshoot

If you encounter any issues while running the scan:

- **Authentication Issues:** Ensure your AWS credentials are correctly configured. You can do this using the AWS CLI with the command aws configure.

- **Permission Issues:** Ensure the IAM user or role associated with your credentials has the necessary permissions to list and check the S3 buckets.

- **`cnspec` Installation Issues:** If you have trouble installing cnspec, ensure you're following the instructions on the installation page correctly.

Should you encounter a problem that is not addressed in this guide, feel free to open an issue in this Github repository. For ongoing issues or broader discussions, we invite you to join us over at our [Github discussions](https://github.com/orgs/mondoohq/discussions) page. We're here to help!
