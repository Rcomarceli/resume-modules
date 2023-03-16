package test

import (
	"fmt"
	"testing"
	"time"

	"strings"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/logger"

	"github.com/chromedp/chromedp"
	"context"
)

// we will override terraform variables with github secrets for testing
func TestFrontend(t *testing.T) {
	t.Parallel()

	ctx, cancel := chromedp.NewContext(context.Background())
	defer cancel()

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
			"environment":         "sandbox",
			"website_bucket_name": instanceName,
			"api_url":             "bad_api_url",
			"allowed_ip_range":    []string{"0.0.0.0/0"},
		},
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created.
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`. Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the IP of the instance
	websiteEndpoint := terraform.Output(t, terraformOptions, "website_endpoint")

	url := fmt.Sprintf("http://%s", websiteEndpoint)
	http_helper.HttpGetWithRetryWithCustomValidation(t, url, nil, 10, 5*time.Second, validateHtml)

	validationstr := "rcomarceli@gmail.com"
	targetId := "#email-link-for-testing"

	validateBody(t, ctx, url, targetId, validationstr)
}

func validateHtml(statusCode int, body string) bool {
	if statusCode != 200 {
		return false
	}
	
	// if we get a website, ensure its our website and not cloudflares

	return true
}

func validateBody(t *testing.T, ctx context.Context, urlstr string, targetId string, validationstr string) {
	var innerHTML string
	logger.Logf(t, "Opening headless browser to %s, searching for string %s, at id %s", urlstr, validationstr, targetId)
	if err := chromedp.Run(ctx,
		chromedp.Navigate(urlstr),
		chromedp.InnerHTML(targetId, &innerHTML, chromedp.ByID),
	); err != nil {
		t.Fatal(err)
	}

	fmt.Println(innerHTML == validationstr)

	if (innerHTML != validationstr) {
		t.Fatal(fmt.Sprintf("body HTML doesnt match target string %s!", validationstr))
	}
}