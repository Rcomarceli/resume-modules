package test

import (
	"fmt"
	"testing"
	"time"
	"os"
	"strings"
	// "strconv"

	"net/http"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/retry"

	"github.com/chromedp/chromedp"
	"context"
)

// we will override terraform variables with github secrets for testing
// wip:
// api url relies on cloudflare workers so we need to include DNS in this integration test as well
// improve local iteration setup (should take priority)

// just combining all tests for dns and www in one here

func TestIntegration(t *testing.T) {
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
		TerraformDir: "../../examples/integration",
		Vars:         combinedVars,
	})


	// At the end of the test, run `terraform destroy` to clean up any resources that were created.
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`. Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the IP of the instance
	websiteEndpoint := terraform.Output(t, terraformOptions, "website_endpoint")

	// verify we can access the site through the S3 website bucket endpoint
	url := fmt.Sprintf("http://%s", websiteEndpoint)
	http_helper.HttpGetWithRetryWithCustomValidation(t, url, nil, 10, 5*time.Second, validateHtml)

	
	// 
	httpUrl := fmt.Sprintf("http://%s", os.Getenv("CLOUDFLARE_DOMAIN"))
	httpsUrl := fmt.Sprintf("https://%s/", os.Getenv("CLOUDFLARE_DOMAIN"))
	wwwUrl := fmt.Sprintf("http://www.%s", os.Getenv("CLOUDFLARE_DOMAIN"))

	// validate http to https redirect
	verifyRedirect(t, httpUrl, httpsUrl, 30, 5*time.Second)

	// verify www to non-www https redirect
	verifyRedirect(t, wwwUrl, httpsUrl, 30, 5*time.Second)

	validationstr := "rcomarceli@gmail.com"
	targetId := "#email-link-for-testing"
	validateBody(t, ctx, url, targetId, validationstr)
}

func verifyRedirect(t *testing.T, targetUrl string, expectedRedirectUrl string, retries int, sleepBetweenRetries time.Duration) {

	retry.DoWithRetry(t, fmt.Sprintf("HTTP GET to %s", targetUrl), retries, sleepBetweenRetries, func() (string, error) {
		client := &http.Client{
			CheckRedirect: func(req *http.Request, via []*http.Request) error {
				return http.ErrUseLastResponse
			},
		}

		response, err := client.Get(targetUrl)
		if err != nil {
			return "", NonFatalError{Url: targetUrl, Message: "GET failed"}
		}

		if response.StatusCode != http.StatusMovedPermanently {
			return "", NonFatalError{Url: targetUrl, Message: fmt.Sprintf("Wrong status code. Expected %d, got %d", http.StatusMovedPermanently, response.StatusCode)}
		}

		location := response.Header.Get("Location")
		if location != expectedRedirectUrl {
			return "", NonFatalError{Url: targetUrl, Message: fmt.Sprintf("Redirect Url wrong. Expected %s, got %s", expectedRedirectUrl, location)}
		}
		defer response.Body.Close()

		return "", err
	})

}

type NonFatalError struct {
	Url     string
	Message string
}

func (err NonFatalError) Error() string {
	return fmt.Sprintf("Validation failed for URL %s. Message: %s", err.Url, err.Message)
}

func validateHtml(statusCode int, body string) bool {
	if statusCode != 200 {
		return false
	}
	// could validate body here
	return true
}


func validateBody(t *testing.T, ctx context.Context, urlstr string, targetId string, validationstr string) {
	var innerHTML string
	// var visitorCount1 string
	// var visitorCount2 string

	logger.Logf(t, "Opening headless browser to %s, searching for string %s, at id %s", urlstr, validationstr, targetId)
	if err := chromedp.Run(ctx,
		chromedp.Navigate(urlstr),
		chromedp.InnerHTML(targetId, &innerHTML, chromedp.ByID),
		// chromedp.InnerHTML(`[data-cy="visitorcount"]`, &visitorCount1, chromedp.ByQuery),
	); err != nil {
		t.Fatal(err)
	}

	fmt.Println(innerHTML == validationstr)
	// logger.Logf(t, "visitor count is %s", &visitorCount1)

	// if (innerHTML != validationstr) {
	// 	t.Fatal(fmt.Sprintf("body HTML doesnt match target string %s!", validationstr))
	// }

	// // second visit: verify if the visitor count has incremented correctly
	// if err := chromedp.Run(ctx,
	// 	chromedp.Navigate(urlstr),
	// 	chromedp.InnerHTML(`[data-cy="visitorcount"]`, &visitorCount2, chromedp.ByQuery),
	// ); err != nil {
	// 	t.Fatal(err)
	// }

	// count1, err := strconv.Atoi(visitorCount1)
	// if err != nil {
	// 	t.Fatalf("Failed to convert visitor count 1 to integer: %v", err)
	// }
	// count2, err := strconv.Atoi(visitorCount2)
	// if err != nil {
	// 	t.Fatalf("Failed to convert visitor count 2 to integer: %v", err)
	// }

	// if count2 <= count1 {
	// 	t.Fatalf("Visitor count did not increment between visits!")
	// }

}

