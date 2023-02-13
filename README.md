# resume-modules

Git Repository of the Terraform modules I used to create my resume!

In the repo, you'll find the modules:
- Frontend: Deploys the website and underlying AWS infrastructure.
- Backend: Deploys the AWS lambda code and API for the frontend visitor counter
- DNS: Deploys the Cloudflare DNS records needed for the resume domain and the redirects (http --> https)
- www: Deploys the Cloudflare www to non-www redirect (This was made separate to make dev and prod testing possible on the same domain)

The "examples" folder provide examples of how you'd deploy the module in a live terraform file, but they are also used for validation, unit, and integration testing defined in the github action workflows.

The "tests" folder contains the terratest code deployed on each push to the github repo. It contains:
- validate: Validation test. Check for syntax errors, missing variables, etc
- unit: Unit testing. Deploy certain modules and validate expected outputs.
- integration: Integration testing. Currently deploys DNS and Frontend for DNS testing.

End to end testing is being done in the resume-live repo, which defines the actual files that use these modules to deploy whats in my dev and prod environments.

Overall, the purpose of this separate repo is for automated testing (made possible in Terraform via modules) and versioned releases to allow us to only deploy tried-and-true versions in live while still allowing for constant commits on the module repo.