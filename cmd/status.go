package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Display cluster status",
	Long:  "Show nodes and system pods of the Talos Kubernetes cluster.",
	Run: func(cmd *cobra.Command, args []string) {

		fmt.Println("Checking cluster status...")
		fmt.Println("")

		// -----------------------------
		// GET BASE PATH
		// -----------------------------
		basePath := os.Getenv("TALOS_LAB_HOME")
		if basePath == "" {
			fmt.Println("[ERROR] TALOS_LAB_HOME is not set")
			os.Exit(1)
		}

		command := exec.Command("bash", basePath+"/bash_cmd/status.sh")
		command.Stdout = os.Stdout
		command.Stderr = os.Stderr

		err := command.Run()
		if err != nil {
			fmt.Println("Error:", err)
			os.Exit(1)
		}
	},
}

func init() {
	rootCmd.AddCommand(statusCmd)
}