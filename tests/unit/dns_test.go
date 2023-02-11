package test

import (
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"net/http"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"

	"github.com/gruntwork-io/terratest/modules/retry"

	// "github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

// we will override terraform variables with github secrets for testing

// we will use environment-variables here that *should* be defined in our github repo

func TestDns(t *testing.T) {
	t.Parallel()

	uniqueId := random.UniqueId()
	// convert unique ID to lowercase since s3 buckets don't accept uppercase
	uniqueIdLowercase := strings.ToLower(uniqueId)
	instanceName := fmt.Sprintf("terratest-frontend-%s", uniqueIdLowercase)

	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/dns",
		Vars: map[string]interface{}{
			// frontend variables
			"environment":         "sandbox",
			"website_bucket_name": instanceName,
			"api_url":             "bad_api_url",
			"allowed_ip_range":    []string{"0.0.0.0/0"},
			// DNS variables. Set via environmental variables
			"cloudflare_api_token":  os.Getenv("CLOUDFLARE_API_TOKEN"),
			"cloudflare_zone_id":    os.Getenv("CLOUDFLARE_ZONE_ID"),
			"cloudflare_domain":     os.Getenv("CLOUDFLARE_DOMAIN"),
			"cloudflare_account_id": os.Getenv("CLOUDFLARE_ACCOUNT_ID"),
		},
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created.
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`. Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the IP of the instance
	// websiteEndpoint := terraform.Output(t, terraformOptions, "website_endpoint")
	// websiteEtag := terraform.Output(t, terraformOptions, "website_html_etag")

	// http_helper.HttpGetWithRetry(t, url, nil, 200, nil, 10, 5*time.Second)
	// http_helper.HttpGetWithRetry(t, url, nil, 200, "Hello, World!", 30, 5*time.Second)
	httpUrl := fmt.Sprintf("http://%s", os.Getenv("CLOUDFLARE_DOMAIN"))
	httpsUrl := fmt.Sprintf("https://%s/", os.Getenv("CLOUDFLARE_DOMAIN"))
	wwwUrl := fmt.Sprintf("http://www.%s", os.Getenv("CLOUDFLARE_DOMAIN"))

	// verify https returns 200
	http_helper.HttpGetWithRetryWithCustomValidation(t, httpsUrl, nil, 50, 5*time.Second, validateHtml)

	// verify www returns 200
	http_helper.HttpGetWithRetryWithCustomValidation(t, wwwUrl, nil, 50, 5*time.Second, validateHtml)

	// validate http to https redirect
	verifyRedirect(t, httpUrl, httpsUrl, 30, 5*time.Second)

	// verify www to non-www https redirect
	verifyRedirect(t, wwwUrl, httpsUrl, 30, 5*time.Second)
}

func verifyRedirect(t *testing.T, targetUrl string, expectedRedirectUrl string, retries int, sleepBetweenRetries time.Duration) {

	// _, err := retry.DoWithRetry(t, fmt.Sprintf("HTTP GET to %s", targetUrl), retries, sleepBetweenRetries, func() (string, error) {
	retry.DoWithRetry(t, fmt.Sprintf("HTTP GET to %s", targetUrl), retries, sleepBetweenRetries, func() (string, error) {
		client := &http.Client{
			CheckRedirect: func(req *http.Request, via []*http.Request) error {
				return http.ErrUseLastResponse
			},
		}

		// targetUrl := httpUrl
		// expectedRedirectUrl := httpsUrl

		response, err := client.Get(targetUrl)
		if err != nil {
			// t.Fatalf("Failed to GET URL %s: %s", targetUrl, err)
			return "", ThisThingFailed{Url: targetUrl, Message: "GET failed"}
		}

		if response.StatusCode != http.StatusMovedPermanently {
			// t.Fatalf("Expected HTTP status code %d but got %d", http.StatusMovedPermanently, response.StatusCode)
			return "", ThisThingFailed{Url: targetUrl, Message: fmt.Sprintf("Wrong status code. Expected %d, got %d", http.StatusMovedPermanently, response.StatusCode)}
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

type ThisThingFailed struct {
	Url     string
	Message string
}

func (err ThisThingFailed) Error() string {
	return fmt.Sprintf("Validation failed for URL %s. Message: %s", err.Url, err.Message)
	// return fmt.Sprintf("Validation failed for URL %s. Response status: %d. Response body:\n%s", err.Url, err.Status, err.Body)
}
