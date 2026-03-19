package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

// configCmd represents the config command
var configCmd = &cobra.Command{
	Use:   "config",
	Short: "Validate configuration file",
	Long:  "Validate the servers.json configuration before running cluster operations.",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Validating configuration...")

		// -----------------------------
		// GET BASE PATH
		// -----------------------------
		basePath := os.Getenv("TALOS_LAB_HOME")
		if basePath == "" {
			fmt.Println("[ERROR] TALOS_LAB_HOME is not set")
			os.Exit(1)
		}

		command := exec.Command("bash", basePath+"/bash_cmd/validate_config.sh")
		command.Stdout = os.Stdout
		command.Stderr = os.Stderr

		err := command.Run()
		if err != nil {
			fmt.Println("Validation failed:", err)
			os.Exit(1)
		}

		fmt.Println("Configuration is valid.")
	},
}

func init() {
	validateCmd.AddCommand(configCmd)
}