package test

import (
	"fmt"
	"testing"
	"time"

	"strings"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

// we will override terraform variables with github secrets for testing
func TestTerraformBackend(t *testing.T) {
	t.Parallel()

	// append unique names to given variables for terraform
	uniqueVars := map[string]interface{}{
		"lambda_bucket_name":     "backend",
		"function_name":          "updatevisitorcounter",
		"lambda_iam_role_name":   "iamrolename",
		"lambda_iam_policy_name": "iampolicyname",
		"api_gateway_name":       "apigateway",
		"api_gateway_stage_name": "v1",
		"lambda_permission_name": "lambdapermission",
		"database_name":          "website-db",
	}
	uniqueId := random.UniqueId()
	prefix := "terratest"
	uniqueIdLowercase := strings.ToLower(uniqueId)

	for k, v := range uniqueVars {
		// append uniqueID only if the value is of type string
		if value, ok := v.(string); ok {
			uniqueVars[k] = fmt.Sprintf("%s-%s-%s", prefix, value, uniqueIdLowercase)
		}
	}

	otherVars := map[string]interface{}{
		"scope_permissions_arn": "arn:aws:iam::681163022059:policy/ScopePermissions",
		"cloudflare_domain":     "bad_domain",
		"environment":           "sandbox",
	}

	// then combine all needed variables to pass to terratest terraformOptions
	combinedVars := map[string]interface{}{}

	for k, v := range uniqueVars {
		combinedVars[k] = v
	}

	for k, v := range otherVars {
		combinedVars[k] = v
	}

	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/backend",
		Vars:         combinedVars,
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created.
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`. Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	apiUrl := terraform.Output(t, terraformOptions, "api_url")

	// attempt to keep incrementing the visitor counter until we get "2".
	http_helper.HTTPDoWithValidationRetry(t, "POST", apiUrl, nil, nil, 200, "2", 10, 5*time.Second, nil)
}
