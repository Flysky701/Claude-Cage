package workbench

import (
	"testing"
	"time"
)

func TestWindowsFramePacingAdaptsWithoutChangingPixels(t *testing.T) {
	var pacing windowsFramePacing
	if got := pacing.interval(); got != time.Second/60 {
		t.Fatalf("initial pacing: %v", got)
	}
	for i := 0; i < 8; i++ {
		pacing.observe(5*time.Millisecond, true)
	}
	if got := pacing.interval(); got < 60*time.Millisecond {
		t.Fatalf("idle capture is too busy: %v", got)
	}
	pacing.observe(5*time.Millisecond, false)
	if got := pacing.interval(); got != time.Second/60 {
		t.Fatalf("motion did not recover: %v", got)
	}
	pacing.observe(80*time.Millisecond, false)
	if got := pacing.interval(); got < 30*time.Millisecond || got > 100*time.Millisecond {
		t.Fatalf("slow capture backpressure: %v", got)
	}
	for i := 0; i < 12; i++ {
		pacing.observe(4*time.Millisecond, false)
	}
	if got := pacing.interval(); got != time.Second/60 {
		t.Fatalf("fast capture did not recover: %v", got)
	}
}
