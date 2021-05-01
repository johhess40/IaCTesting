package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestBurlington(t *testing.T) {

	// The path to where our Terraform code is stored
	terraformOptions := &terraform.Options{
		TerraformDir: "..",
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

}
