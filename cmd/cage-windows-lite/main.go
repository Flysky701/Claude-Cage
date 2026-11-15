// cage-windows-lite is the deliberately separate backend for the Windows Lite
// review build. It never dispatches commands to the installed Cage/VM backend.
package main

import (
	"os"

	"github.com/sylvinus/agent-vm/internal/windowslite"
)

func main() { os.Exit(windowslite.Run(os.Args[1:])) }
