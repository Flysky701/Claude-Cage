//go:build !windows

package workbench

import (
	"errors"
	"net"
)

func listenLocalNetworkPipe(string) (net.Listener, error) {
	return nil, errors.New("Windows 本地账户网络仅在 Windows 上可用")
}
