/*
The way that this test is written it can be used to test
multiple variations of a terraform config based on different
tfvars files. Future additions to this test could include validating
NSG rules, ingress for K8's, etc. - John Hession
*/

package test

import (
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

var varsFiles = map[string]string{
	"varsDev":  "webappdev.tfvars",
	"varsQA":   "webappqa.tfvars",
	"varsProd": "webappprod.tfvars",
}

func TestBurlington(t *testing.T) {

	stdOut := os.Stdout

	defer func() {
		os.Stdout = stdOut
	}()
	os.Stdout = os.NewFile(0, os.DevNull)
	t.Log("Running Tests For All Envs")

	// The path to where our Terraform code is stored
	terraformOptions := &terraform.Options{
		TerraformDir: "..",
	}

	// defer terraform.Destroy(t, terraformOptions)

	// Running Terraform Init and Plan only and writing it out to a file
	// These are the plan files we want to create, they can be named anything we would like
	devtfPlan := "webappdev.tfplan"
	qatfPlan := "webappqa.tfplan"
	prodtfPlan := "webappprod.tfplan"

	// Reference the tfvars files created earlier which will test values for separate environments
	tfVars := []string{
		varsFiles["varsDev"],
		varsFiles["varsQA"],
		varsFiles["varsProd"],
	}

	envBurl := map[string]string{
		"devEnvName":  "Dev",
		"qaEnvName":   "QA",
		"prodEnvName": "Prod",
	}

	// Re-initialize the backend and all modules if any have been added
	terraform.Init(t, terraformOptions)
	// As we loop through each vars file we evaluate based on expected file name
	// Looping through the plan step for Terraform with each tfvars file
	for _, plan := range tfVars {

		if plan == tfVars[0] {

			var tfVal string = terraform.Validate(t, terraformOptions)

			resDev := strings.Contains(tfVal, "configuration is valid")

			if resDev == true {
				// Since terraform config is valid or "true" continue testing with plan
				valStatus := "Valid"

				t.Log(envBurl["devEnvName"], "Configuration Status:", valStatus)
				// Running terraform plan command and write out to a .tfplan file
				terraform.RunTerraformCommand(t, terraformOptions, terraform.FormatArgs(terraformOptions, "plan", "-var-file="+tfVars[0], "-out="+devtfPlan)...)

				t.Log("Plan File", devtfPlan, "Has Been \nManifested For Development Environment")

			} else {
				t.Log(envBurl["devEnvName"], "Test was not valid, please check terraform logs for errors")
			}

		} else if plan == tfVars[1] {

			var tfVal string = terraform.Validate(t, terraformOptions)

			resQa := strings.Contains(tfVal, "configuration is valid")

			if resQa == true {

				valStatus := "Valid"

				t.Log(envBurl["qaEnvName"], "Configuration Status:", valStatus)

				terraform.RunTerraformCommand(t, terraformOptions, terraform.FormatArgs(terraformOptions, "plan", "-var-file="+tfVars[1], "-out="+qatfPlan)...)

				t.Log("Plan File", qatfPlan, "Has Been Manifested For QA Environment")

			} else {
				t.Log(envBurl["qaEnvName"], "Test was not valid, please check terraform logs for errors")
			}

		} else if plan == tfVars[2] {

			var tfVal string = terraform.Validate(t, terraformOptions)

			resProd := strings.Contains(tfVal, "configuration is valid")

			if resProd == true {

				valStatus := "Valid"

				t.Log(envBurl["prodEnvName"], "Configuration Status:", valStatus)

				terraform.RunTerraformCommand(t, terraformOptions, terraform.FormatArgs(terraformOptions, "plan", "-var-file="+tfVars[2], "-out="+prodtfPlan)...)

				t.Log("Plan File", prodtfPlan, "Has Been \nManifested For Production Environment")

			} else {
				t.Log(envBurl["prodEnvName"], "Test was not valid, please check terraform logs for errors")
			}
		}
	}
}
