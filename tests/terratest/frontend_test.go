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
func TestTerraformAwsHelloWorldExample(t *testing.T) {
	t.Parallel()

	uniqueId := random.UniqueId()
	// convert unique ID to lowercase since s3 buckets don't accept uppercase
	uniqueIdLowercase := strings.ToLower(uniqueId)
	instanceName := fmt.Sprintf("terratest-frontend-%s", uniqueIdLowercase)

	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/frontend",
		Vars: map[string]interface{}{
			"bucket_name":      instanceName,
			"api_url":          "bad_api_url",
			"allowed_ip_range": []string{"0.0.0.0/0"},
		},
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created.
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`. Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the IP of the instance
	websiteEndpoint := terraform.Output(t, terraformOptions, "website_endpoint")
	// websiteEtag := terraform.Output(t, terraformOptions, "website_html_etag")

	// note that this check for the rendered html file only works because we arent expecting any content to change in an isolated test without any lambda function
	// https://github.com/gruntwork-io/terratest/issues/200
	// Make an HTTP request to the instance and make sure we get back a 200 OK with the body "Hello, World!"
	url := fmt.Sprintf("http://%s", websiteEndpoint)
	http_helper.HttpGetWithRetryWithCustomValidation(t, url, nil, 10, 5*time.Second, validateHtml)
	// http_helper.HttpGetWithRetry(t, url, nil, 200, nil, 10, 5*time.Second)
	// http_helper.HttpGetWithRetry(t, url, nil, 200, "Hello, World!", 30, 5*time.Second)
}

func validateHtml(statusCode int, body string) bool {
	if statusCode != 200 {
		return false
	}
	// could validate body here
	return true
}
