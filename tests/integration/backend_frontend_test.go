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
// going to need to specify source in frontend module..?
// need to solve how we're going to build it
func TestFrontend(t *testing.T) {
	t.Parallel()

	ctx, cancel := chromedp.NewContext(context.Background())
	defer cancel()

	uniqueVars := map[string]interface{}{
		"environment":         "sandbox",
		"lambda_bucket_name":     "backend",
		"function_name":          "updatevisitorcounter",
		"lambda_iam_role_name":   "iamrolename",
		"lambda_iam_policy_name": "iampolicyname",
		"api_gateway_name":       "apigateway",
		"api_gateway_stage_name": "v1",
		"lambda_permission_name": "lambdapermission",
		"database_name":          "website-db",
		"website_bucket_name": "frontend-integration",
		// api_url: specified in terraform example file as an output from backend

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
		"environment":           "sandbox",
		"cloudflare_api_token":  os.Getenv("CLOUDFLARE_API_TOKEN"),
		"cloudflare_zone_id":    os.Getenv("CLOUDFLARE_ZONE_ID"),
		"cloudflare_domain":     os.Getenv("CLOUDFLARE_DOMAIN"),
		"cloudflare_account_id": os.Getenv("CLOUDFLARE_ACCOUNT_ID"),
		"allowed_ip_range":    []string{"0.0.0.0/0"},
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
		TerraformDir: "../../examples/frontend_backend_integration",
		Vars:         combinedVars,
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