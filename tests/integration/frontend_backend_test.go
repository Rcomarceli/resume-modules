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
func TestFrontend(t *testing.T) {
	t.Parallel()

	// append unique names to given variables for terraform
	uniqueVars := map[string]interface{}{
		// backend vars
		"lambda_bucket_name":     "backend",
		"function_name":          "updatevisitorcounter",
		"lambda_iam_role_name":   "iamrolename",
		"lambda_iam_policy_name": "iampolicyname",
		"api_gateway_name":       "apigateway",
		"api_gateway_stage_name": "v1",
		"lambda_permission_name": "lambdapermission",
		"database_name":          "website-db",
		// frontend vars
		"website_bucket_name": "frontend",
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
		"allowed_ip_range":      []string{"0.0.0.0/0"},
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
		TerraformDir: "../../examples/testing/frontendbackend",
		Vars:         combinedVars,
	})
	// At the end of the test, run `terraform destroy` to clean up any resources that were created.
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`. Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the IP of the instance
	websiteEndpoint := terraform.Output(t, terraformOptions, "website_endpoint")

	url := fmt.Sprintf("http://%s", websiteEndpoint)
	http_helper.HttpGetWithRetryWithCustomValidation(t, url, nil, 10, 5*time.Second, validateVisitorCounter)

	// next we will have to check if the visitor counter is incrementing on each get
}

func verifyVisitorCounter(t *testing.T, targetUrl string, expectedRedirectUrl string, retries int, sleepBetweenRetries time.Duration) {

	// test to see if a t.fatal error gets returned
	retry.DoWithRetry(t, fmt.Sprintf("HTTP GET to %s", targetUrl), retries, sleepBetweenRetries, func() (string, error) {

		response, err := client.Get(targetUrl)
		if err != nil {
			t.Fatalf("Failed to GET URL %s: %s", targetUrl, err)
			// return "", ThisThingFailed{Url: targetUrl, Message: "GET failed"}
		}

		if response.StatusCode != http.StatusMovedPermanently {
			t.Fatalf("Expected HTTP status code %d but got %d", http.StatusMovedPermanently, response.StatusCode)
			// return "", ThisThingFailed{Url: targetUrl, Message: fmt.Sprintf("Wrong status code. Expected %d, got %d", http.StatusMovedPermanently, response.StatusCode)}
		}

		// redirectedUrl := response.Request.URL.String()
		// redirectedUrl, errLocation := response.Location()
		location := response.Header.Get("Location")
		// if redirectedUrl != expectedRedirectUrl {
		if location != expectedRedirectUrl {
			// t.Fatalf("Expected URL to redirect to %s but got %s", expectedRedirectUrl, redirectedUrl)
			return "", ThisThingFailed{Url: targetUrl, Message: fmt.Sprintf("Redirect Url wrong. Expected %s, got %s", expectedRedirectUrl, location)}
		}
		defer response.Body.Close()

		return "", err
	})

	// if err != nil {
	// 	return err
	// }

}
