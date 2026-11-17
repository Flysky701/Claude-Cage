//go:build ignore

// Native console-only fixture. It never accesses accounts or network services.
package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"
	"unsafe"
)

type coord struct{ X, Y int16 }
type smallRect struct{ Left, Top, Right, Bottom int16 }
type screenInfo struct {
	Size       coord
	Cursor     coord
	Attributes uint16
	Window     smallRect
	Maximum    coord
}

func runTerminalWorker() error {
	if len(os.Args) != 2 {
		return fmt.Errorf("expected size or interrupt")
	}
	kernel := syscall.NewLazyDLL("kernel32.dll")
	if os.Args[1] == "size" {
		var info screenInfo
		ok, _, err := kernel.NewProc("GetConsoleScreenBufferInfo").Call(uintptr(syscall.Stdout), uintptr(unsafe.Pointer(&info)))
		if ok == 0 {
			return fmt.Errorf("GetConsoleScreenBufferInfo: %w", err)
		}
		fmt.Printf("CAGE_CONSOLE_SIZE:%dx%d\n", info.Window.Right-info.Window.Left+1, info.Window.Bottom-info.Window.Top+1)
		return nil
	}
	if os.Args[1] == "interrupt" {
		interrupt := make(chan os.Signal, 1)
		signal.Notify(interrupt, os.Interrupt)
		defer signal.Stop(interrupt)
		fmt.Println("CAGE_INTERRUPT_READY")
		select {
		case <-interrupt:
			fmt.Println("CAGE_CTRL_C_RECEIVED")
			return nil
		case <-time.After(12 * time.Second):
			return fmt.Errorf("interrupt_not_received")
		}
	}
	return fmt.Errorf("unsupported terminal operation")
}

func main() {
	if err := runTerminalWorker(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(3)
	}
}
