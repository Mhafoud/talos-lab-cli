package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var clusterCmd = &cobra.Command{
	Use:   "cluster",
	Short: "Create a Talos cluster",
	Long:  "This command creates a full Talos Kubernetes cluster using existing bash scripts.",
	Run: func(cmd *cobra.Command, args []string) {

		fmt.Println("Starting cluster creation...")
		fmt.Println("")

		// -----------------------------
		// GET BASE PATH
		// -----------------------------
		basePath := os.Getenv("TALOS_LAB_HOME")
		if basePath == "" {
			fmt.Println("[ERROR] TALOS_LAB_HOME is not set")
			os.Exit(1)
		}

		// -----------------------------
		// STEP 0 - Validate config
		// -----------------------------
		fmt.Println("Validating configuration...")

		validateCmd := exec.Command("bash", basePath+"/bash_cmd/validate_config.sh")
		validateCmd.Stdout = os.Stdout
		validateCmd.Stderr = os.Stderr

		err := validateCmd.Run()
		if err != nil {
			fmt.Println("Configuration invalid. Aborting.")
			os.Exit(1)
		}

		fmt.Println("Validation successful.")
		fmt.Println("")

		// -----------------------------
		// STEP 1 - Create cluster
		// -----------------------------
		command := exec.Command("bash", basePath+"/bash_cmd/create_cluster.sh")
		command.Stdout = os.Stdout
		command.Stderr = os.Stderr

		err = command.Run()
		if err != nil {
			fmt.Println("Error:", err)
			os.Exit(1)
		}
	},
}

func init() {
	createCmd.AddCommand(clusterCmd)
}