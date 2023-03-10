# resume-modules

Git Repository of the Terraform modules I used to create my resume! [Link to live repo](https://github.com/Rcomarceli/resume-live)

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

At a high level, the flow goes like this:
- I make a change to the code in this repo (either via push or pull request) and that'll kick off my CI/CD pipeline (Github Actions). This flow focuses more on testing to ensure that the resulting module code doesn't break, starting with a static analysis test to catch any obvious errors.
- If those tests pass, we move onto unit testing for modules to ensure that each individual part is outputting what it needs to. Note that we don't unit test the DNS-related modules since we'd only be testing whether or not Terraform actually applied the changes, which should be handled by Terraform anyway.
- If those tests pass, we move onto integration testing. We test the integration between DNS and the frontend here, making sure we can navigate to the frontend via our desired domain name, as well as whether or not our redirects are working correctly (http --> https, www --> non-www). 
- If those tests pass, our code *should* work, but the final end-to-end test takes place in the resume-live module, which will test if all modules are working correctly and all the actions the user can take (which, isn't anything beyond being able to visit the site and see the visitor counter increment.).

Note that there's no integration test for the frontend and backend, since (in this case), it's just basically an end to end test without a DNS resolution. I opt for an end to end test over the integration test since it lets us use Cypress, which is a robust testing framework. The aforementioned test takes place during the actual deployment stage (in the [resume-live repo](https://github.com/Rcomarceli/resume-live)), where we maintain an existing test environment for *incremental* end to end testing (see: https://youtu.be/xhHOW0EF5u8?t=2541).

End to end testing is being done in the resume-live repo, which defines the actual files that use these modules to deploy whats in my dev and prod environments.

Overall, the purpose of this separate repo is for automated testing (made possible in Terraform via modules) and versioned releases to allow us to only deploy tried-and-true versions in live while still allowing for constant commits on the module repo.