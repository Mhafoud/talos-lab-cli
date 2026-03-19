package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

// destroyCmd represents the destroy command
var destroyCmd = &cobra.Command{
	Use:   "destroy",
	Short: "Destroy Talos cluster",
	Run: func(cmd *cobra.Command, args []string) {

		// -------------------------------
		// Confirmation utilisateur
		// -------------------------------
		fmt.Print("⚠️  Are you sure you want to destroy the cluster? (y/n): ")
		var input string
		fmt.Scanln(&input)

		if input != "y" {
			fmt.Println("Aborted")
			return
		}

		fmt.Println("")
		fmt.Println("[INFO] Starting cluster destruction...")
		fmt.Println("")

		// -----------------------------
		// GET BASE PATH
		// -----------------------------
		basePath := os.Getenv("TALOS_LAB_HOME")
		if basePath == "" {
			fmt.Println("[ERROR] TALOS_LAB_HOME is not set")
			os.Exit(1)
		}

		// -------------------------------
		// Exécution du script Bash
		// -------------------------------
		command := exec.Command("bash", basePath+"/bash_cmd/destroy_cluster.sh")

		command.Stdout = os.Stdout
		command.Stderr = os.Stderr

		err := command.Run()
		if err != nil {
			fmt.Println("")
			fmt.Println("[ERROR] Destroy failed:", err)
			os.Exit(1)
		}

		fmt.Println("")
		fmt.Println("[SUCCESS] Destroy command completed")
		fmt.Println("")
	},
}

func init() {
	rootCmd.AddCommand(destroyCmd)
}