package workbench

import "time"

// Keep native PNG pixels unchanged. Reduce redundant idle captures and use
// measured capture backpressure, rather than accumulating frames for playback.
type windowsFramePacing struct {
	cost time.Duration
	idle int
}

func (p *windowsFramePacing) observe(cost time.Duration, unchanged bool) {
	if cost > p.cost {
		p.cost = cost
	} else {
		p.cost = (p.cost*3 + cost) / 4
	}
	if unchanged {
		if p.idle < 8 {
			p.idle++
		}
	} else {
		p.idle = 0
	}
}

func (p *windowsFramePacing) interval() time.Duration {
	interval := time.Second / 60
	if p.cost > interval {
		interval = p.cost
	}
	if p.idle >= 4 && interval < time.Second/15 {
		interval = time.Second / 15
	}
	if interval > 100*time.Millisecond {
		interval = 100 * time.Millisecond
	}
	return interval
}
