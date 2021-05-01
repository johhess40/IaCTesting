package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

var varsFiles = map[string]string{
	"varsDev":  "webappdev.tfvars",
	"varsQA":   "webappqa.tfvars",
	"varsProd": "webappprod.tfvars",
}

func TestBurlington(t *testing.T) {

	// The path to where our Terraform code is stored
	terraformOptions := &terraform.Options{
		TerraformDir: "..",
	}

	// defer terraform.Destroy(t, terraformOptions)

	// Running Terraform Init and Plan only and writing it out to a file

	devtfPlan := "webappdev.tfplan"

	qatfPlan := "webappqa.tfplan"

	prodtfPlan := "webappprod.tfplan"

	tfVars := []string{
		varsFiles["varsDev"],
		varsFiles["varsQA"],
		varsFiles["varsProd"],
	}

	terraform.Init(t, terraformOptions)

	for _, plan := range tfVars {
		if plan == tfVars[0] {
			terraform.RunTerraformCommand(t, terraformOptions, terraform.FormatArgs(terraformOptions, "plan", "-var-file="+tfVars[2], "-out="+devtfPlan)...)
		} else if plan == tfVars[1] {
			terraform.RunTerraformCommand(t, terraformOptions, terraform.FormatArgs(terraformOptions, "plan", "-var-file="+tfVars[1], "-out="+qatfPlan)...)
		} else if plan == tfVars[2] {
			terraform.RunTerraformCommand(t, terraformOptions, terraform.FormatArgs(terraformOptions, "plan", "-var-file="+tfVars[2], "-out="+prodtfPlan)...)
		}
	}
}
