package test

import (
	"fmt"
	"testing"
	"time"

	"strings"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"

	"github.com/tebeka/selenium"
	"github.com/tebeka/selenium/chrome"
)

// we will override terraform variables with github secrets for testing
func TestFrontend(t *testing.T) {
	t.Parallel()

	service, err := selenium.NewChromeDriverService("./selenium_deps/chromedriver", 4444)
    if err != nil {
        panic(err)
    }
    defer service.Stop()

    caps := selenium.Capabilities{}
    caps.AddChrome(chrome.Capabilities{Args: []string{
        "window-size=1920x1080",
        "--no-sandbox",
        "--disable-dev-shm-usage",
        "disable-gpu",
        "--headless",  // comment out this line to see the browser
    }})

    wd, err := selenium.NewRemote(caps, "")
    if err != nil {
        panic(err)
    }

    wd.Get("https://www.google.com")
	
	if err := wd.Get("http://play.golang.org/?simple=1"); err != nil {
		panic(err)
	}

	// Get a reference to the text box containing code.
	elem, err := wd.FindElement(selenium.ByCSSSelector, "#code")
	if err != nil {
		panic(err)
	}
	// Remove the boilerplate code already in the text box.
	if err := elem.Clear(); err != nil {
		panic(err)
	}

	// Enter some new code in text box.
	err = elem.SendKeys(`
		package main
		import "fmt"

		func main() {
			fmt.Println("Hello WebDriver!\n")
		}
	`)
	if err != nil {
		panic(err)
	}

	// Click the run button.
	btn, err := wd.FindElement(selenium.ByCSSSelector, "#run")
	if err != nil {
		panic(err)
	}
	if err := btn.Click(); err != nil {
		panic(err)
	}

	// Wait for the program to finish running and get the output.
	outputDiv, err := wd.FindElement(selenium.ByCSSSelector, "#output")
	if err != nil {
		panic(err)
	}

	var output string
	for {
		output, err = outputDiv.Text()
		if err != nil {
			panic(err)
		}
		if output != "Waiting for remote server..." {
			break
		}
		time.Sleep(time.Millisecond * 100)
	}

	fmt.Printf("%s", strings.Replace(output, "\n\n", "\n", -1))

	// Example Output:
	// Hello WebDriver!
	//
	// Program exited.

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

}

func validateHtml(statusCode int, body string) bool {
	if statusCode != 200 {
		return false
	}
	
	// if we get a website, ensure its our website and not cloudflares

    // Find the specific element(s) you're interested in


	if !strings.Contains(body, "rcomarceli@gmail.com") {
		return false
	}

	// could validate body here
	return true
}
