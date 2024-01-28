# GitHub: Running the CIS GitHub Benchmark with cnspec

> NOTE: CIS GitHub Benchmark requires a subscription

## Overview

This guide provides an example on how to execute the CIS (Center for Internet Security) GitHub Benchmark on GitHub repositories and organizations using the `cnspec` and Mondoo Platform. These benchmarks offer a standardized set of procedures to assess the security posture of GitHub repositories and organizations, helping to identify vulnerabilities or potential areas for security enhancements.

## Pre-requisites

- Mondoo Space: Create a new space on Mondoo Platform and activate the 'CIS GitHub Benchmark - Level 1' benchmark in the Security Registry.
- `cnspec` Login: Authenticate with your newly created Mondoo space using `cnspec login -t <yourtoken>` .
- Organization Access: Ensure you have access to the target GitHub organization, for example https://github.com/lunalectric.
- GitHub Token: Generate a GitHub token with Resource owner set to lunalectric and all permissions set to read.

## Instructions

### CLI: Scanning an Individual Repository

Set your GitHub token as an environment variable with the name GITHUB_TOKEN:

```bash
export GITHUB_TOKEN='your_github_token'
```

> Note: GitHub's fine-grained tokens currently do not allow you to verify packages. For updates, follow this GitHub Roadmap issue.

Then, use `cnspec` to scan an individual repository. For example, to scan the online-shop repository in the lunalectric organization with the mondoo-github-organization-security-level-1 policy, use the following command:

```bash
cnspec scan github repo lunalectric/online-shop
```

### Scanning the Organization

To scan all repositories in the `lunalectric` organization with the `mondoo-github-organization-security-level-1` policy, use the following command:

```bash
cnspec scan github org lunalectric --discover organization
```

### Mondoo Platform

For more detailed instructions, visit the [Mondoo Platform Documentation](https://mondoo.com/docs/platform/infra/saas/github/). Remember to enable the `CIS GitHub Benchmark - Level 1` benchmark as described in the documentation.

## Results

Upon successfully running the commands, `cnspec` will generate a report detailing the security status of the scanned GitHub repository or organization. This report will identify any security vulnerabilities and recommend potential areas for improvement in accordance with the CIS GitHub Benchmark.

![cnspec running a GitHub organization scan](github-supply-chain.gif)

## Troubleshoot

If you encounter any issues while performing these steps:

- Authentication Issues: Double-check your Mondoo credentials with `cnspec status` and GitHub token. Ensure they are set correctly in the environment variables.
- Permission Issues: Verify that you have the necessary permissions to access and scan the GitHub organization or repositories. This may involve checking the settings of your GitHub token and your role within the organization.
- Command Execution Issues: If the `cnspec`` commands are not executing as expected, ensure that cnspec is installed and updated to the latest version.

Should you encounter a problem that is not addressed in this guide, feel free to open an issue in this GitHub repository. For ongoing issues or broader discussions, we invite you to join us over at our [GitHub discussions](https://github.com/orgs/mondoohq/discussions) page. We're here to help!
