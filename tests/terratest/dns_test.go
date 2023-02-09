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

	"github.com/gruntwork-io/terratest/modules/logger"
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
	websiteEndpoint := terraform.Output(t, terraformOptions, "website_endpoint")
	// websiteEtag := terraform.Output(t, terraformOptions, "website_html_etag")

	// note that this check for the rendered html file only works because we arent expecting any content to change in an isolated test without any lambda function
	// https://github.com/gruntwork-io/terratest/issues/200
	// Make an HTTP request to the instance and make sure we get back a 200 OK with the body "Hello, World!"
	url := fmt.Sprintf("http://%s", websiteEndpoint)
	http_helper.HttpGetWithRetryWithCustomValidation(t, url, nil, 10, 5*time.Second, validateHtml)
	// http_helper.HttpGetWithRetry(t, url, nil, 200, nil, 10, 5*time.Second)
	// http_helper.HttpGetWithRetry(t, url, nil, 200, "Hello, World!", 30, 5*time.Second)
	anotherUrl := fmt.Sprintf("http://%s", os.Getenv("CLOUDFLARE_DOMAIN"))
	httpsUrl := fmt.Sprintf("https://%s", os.Getenv("CLOUDFLARE_DOMAIN"))
	// wwwUrl := fmt.Sprintf("http://www.%s", os.Getenv("CLOUDFLARE_DOMAIN"))

	// response from below will result in 200s, not 301
	http_helper.HttpGetWithRetryWithCustomValidation(t, httpsUrl, nil, 50, 5*time.Second, validateHtml)

	returnedString, errReturn := retry.DoWithRetryE(t, "HTTP GET to URL THING", 50, 5*time.Second, func() (string, error) {
		// url := "http://example.com"
		// expectedRedirectUrl := "http://www.example.com"

		targetUrl := anotherUrl
		expectedRedirectUrl := httpsUrl

		response, err := http.Get(targetUrl)
		if err != nil {
			// t.Fatalf("Failed to GET URL %s: %s", targetUrl, err)
			return "failed to get url", err
		}

		if response.StatusCode != http.StatusMovedPermanently {
			// t.Fatalf("Expected HTTP status code %d but got %d", http.StatusMovedPermanently, response.StatusCode)
			return "expected wrong status code", err
		}

		redirectedUrl := response.Request.URL.String()
		if redirectedUrl != expectedRedirectUrl {
			// t.Fatalf("Expected URL to redirect to %s but got %s", expectedRedirectUrl, redirectedUrl)
			return "expected url to redirect", err
		}
		response.Body.Close()

		return "outstring", err

	})

	logger.Logf(t, "returnedString is %s", returnedString)
	if errReturn != nil {
		t.Fatalf("returned err %s", errReturn)
	}

	// http_helper.HttpGetWithRetryWithCustomValidation(t, anotherUrl, nil, 50, 5*time.Second, validateRedirect)
	// http_helper.HttpGetWithRetryWithCustomValidation(t, wwwUrl, nil, 50, 5*time.Second, validateRedirect)
}

// func validateRedirect(statusCode int, body string) bool {
// 	if statusCode != 301 {
// 		return false
// 	}
// 	// could validate body here
// 	return true
// }

// func TestUrlRedirect(t *testing.T, timeout, url, expectedRedirectUrl) {
// 	// url := "http://example.com"
// 	// expectedRedirectUrl := "http://www.example.com"

// 	client := http.Client{
// 		// By default, Go does not impose a timeout, so an HTTP connection attempt can hang for a LONG time.
// 		Timeout: time.Duration(timeout) * time.Second,
// 		// Include the previously created transport config
// 		// Transport: tr,
// 	}

// 	response, err := http.Get(url)
// 	if err != nil {
// 		t.Fatalf("Failed to GET URL %s: %s", url, err)
// 	}
// 	defer response.Body.Close()

// 	if response.StatusCode != http.StatusMovedPermanently {
// 		t.Fatalf("Expected HTTP status code %d but got %d", http.StatusMovedPermanently, response.StatusCode)
// 	}
// 	redirectedUrl := response.Request.URL.String()
// 	if redirectedUrl != expectedRedirectUrl {
// 		t.Fatalf("Expected URL to redirect to %s but got %s", expectedRedirectUrl, redirectedUrl)
// 	}

// }

// func HttpGetWithOptionsE(t testing.TestingT, options HttpGetOptions) (int, string, error) {
// 	logger.Logf(t, "Making an HTTP GET call to URL %s", options.Url)

// 	// Set HTTP client transport config
// 	tr := http.DefaultTransport.(*http.Transport).Clone()
// 	tr.TLSClientConfig = options.TlsConfig

// 	client := http.Client{
// 		// By default, Go does not impose a timeout, so an HTTP connection attempt can hang for a LONG time.
// 		Timeout: time.Duration(options.Timeout) * time.Second,
// 		// Include the previously created transport config
// 		Transport: tr,
// 	}

// 	resp, err := client.Get(options.Url)
// 	if err != nil {
// 		return -1, "", err
// 	}

// 	defer resp.Body.Close()
// 	body, err := ioutil.ReadAll(resp.Body)

// 	if err != nil {
// 		return -1, "", err
// 	}

// 	return resp.StatusCode, strings.TrimSpace(string(body)), nil
// }
