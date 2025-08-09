## Prompt
The file@entraid_terraform_implementations.md contains 124 `### Terraform Implementation:` headers which are implemantions of the powershell code found before. 

Create a new file called `entraid_terraform_implementations_rev2.md` and do the following for each of those 124 pairs.:

- Make sure the terraform code reflects the powershell to 100% . 
- Use only one decisive terraform snippet, instead of providing two options
- Try to avoid the usage of terraform null resources, instead make use of the following tools in that priority:
 
1. Terraform modules
2. Terraform resources
3. Either the`azapi_resource` , the `azapi_update_resource`, the `azapi_resource_action`, or the `azapi_data_plane_resource`, prefering `azapi_resource` where possible because of its full CRUD abilities.

@https://learn.microsoft.com/en-us/azure/developer/terraform/overview-azapi-provider
4. Only if this doesn't yield any results, try to  suggest another solution (maybe a null resource)

Use the `microsoft.docs.mcp` mcp server and the `terraform` mcp server to gather all information you need for your task.

Do those steps above for each of the 124 checks and get my feedback for each one of those terraform patterns you suggest. 
Only then save this to the new file and continue with the next check in question.