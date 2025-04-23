# How to Use This Repo

This repository contains three approaches to provisioning GitHub resources:

- **`./gh-automation`**: Create resources using a Node.js script.
- **`./tf`**: Create resources using a Terraform setup (requires an Azure Storage Account for the state file).
- A GitHub ISSUES_TEMPLATE and workflow to create repository based on template.

For both solutions, make sure to configure a PAT token or GitHub App with appropriate permissions.

---

## Instructions on Configuring the Terraform State File

See: [Azure-Samples/terraform-github-actions](https://github.com/Azure-Samples/terraform-github-actions)