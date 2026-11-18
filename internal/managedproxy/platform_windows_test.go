package managedproxy

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestWindowsSocketWithLongPrototypeTemp(t *testing.T) {
	cache := `C:\Users\Tester\AppData\Local`
	t.Setenv("LocalAppData", cache)
	longTemp := filepath.Join(cache, strings.Repeat("测", 28))
	t.Setenv("TEMP", longTemp)
	t.Setenv("TMP", longTemp)
	path := Socket(`E:\Cage\prototype-one`)
	if len(path) > 107 || filepath.Dir(filepath.Dir(path)) != cache || path == Socket(`E:\Cage\prototype-two`) {
		t.Fatalf("invalid per-profile control socket %q", path)
	}
}

// A PID reused after a reboot must neither be terminated nor block startup.
func TestStopWindowsCoreForgetsReusedPID(t *testing.T) {
	exe, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	core := filepath.Join(filepath.Dir(exe), "mihomo.exe")
	if err := os.WriteFile(core, []byte("placeholder"), 0700); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = os.Remove(core) })
	for name, pid := range map[string]uint32{"same user": uint32(os.Getpid()), "system": 4} {
		t.Run(name, func(t *testing.T) {
			profile := t.TempDir()
			b, _ := json.Marshal(windowsCoreRecord{PID: pid, Executable: core, Created: 1})
			if err := Write(windowsCoreRecordPath(profile), b); err != nil {
				t.Fatal(err)
			}
			if err := stopWindowsCore(profile); err != nil {
				t.Fatal(err)
			}
			if _, err := os.Lstat(windowsCoreRecordPath(profile)); !os.IsNotExist(err) {
				t.Fatal("stale core record was kept")
			}
		})
	}
}
