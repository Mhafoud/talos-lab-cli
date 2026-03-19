package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

// validateCmd represents the validate command
var validateCmd = &cobra.Command{
	Use:   "validate",
	Short: "Validate configuration files",
	Long:  "Validate configuration before running cluster operations.",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Use 'talos-lab validate config' to validate your configuration file")
	},
}

func init() {
	rootCmd.AddCommand(validateCmd)
}