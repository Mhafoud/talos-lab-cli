package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

// createCmd represents the create command
var createCmd = &cobra.Command{
	Use:   "create",
	Short: "Create resources (cluster, master, etc.)",
	Long:  "Create Talos Kubernetes resources such as control plane or full cluster.",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Use 'talos-lab create cluster' to create a full cluster")
	},
}

func init() {
	rootCmd.AddCommand(createCmd)
}