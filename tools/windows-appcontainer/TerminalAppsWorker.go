//go:build ignore

// Diagnose only the disposable current directory; do not enumerate ancestors.
package main

import (
	"fmt"
	"os"
	"syscall"
	"unsafe"
)

func main() {
	path, err := os.Getwd()
	if err != nil {
		fmt.Printf("CAGE_GETCWD_ERROR:%v\n", err)
		return
	}
	fmt.Println("CAGE_GETCURRENTDIRECTORY_OK")
	wide, _ := syscall.UTF16PtrFromString(path)
	handle, err := syscall.CreateFile(wide, 0, syscall.FILE_SHARE_READ|syscall.FILE_SHARE_WRITE|syscall.FILE_SHARE_DELETE, nil, syscall.OPEN_EXISTING, syscall.FILE_FLAG_BACKUP_SEMANTICS, 0)
	if err != nil {
		fmt.Printf("CAGE_OPEN_CWD_ERROR:%v\n", err)
		return
	}
	defer syscall.CloseHandle(handle)
	fmt.Println("CAGE_OPEN_CWD_OK")
	proc := syscall.NewLazyDLL("kernel32.dll").NewProc("GetFinalPathNameByHandleW")
	for _, flags := range []uintptr{0, 8, 4, 12} {
		buffer := make([]uint16, 32768)
		size, _, failure := proc.Call(uintptr(handle), uintptr(unsafe.Pointer(&buffer[0])), uintptr(len(buffer)), flags)
		if size == 0 {
			fmt.Printf("CAGE_FINAL_PATH_FLAGS_%d_ERROR:%v\n", flags, failure)
		} else {
			fmt.Printf("CAGE_FINAL_PATH_FLAGS_%d_OK\n", flags)
		}
	}
	fmt.Println("CAGE_PATH_DIAGNOSTIC_DONE")
}
