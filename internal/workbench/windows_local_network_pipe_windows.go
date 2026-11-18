package workbench

import (
	"net"

	"github.com/Microsoft/go-winio"
	"golang.org/x/sys/windows"
)

func listenLocalNetworkPipe(name string) (net.Listener, error) {
	user, err := windows.GetCurrentProcessToken().GetTokenUser()
	if err != nil {
		return nil, err
	}
	sid := user.User.Sid.String()
	return winio.ListenPipe(`\\.\pipe\`+name, &winio.PipeConfig{
		SecurityDescriptor: "O:" + sid + "D:P(D;;GA;;;NU)(A;;GA;;;" + sid + ")(A;;GA;;;SY)",
		InputBufferSize:    65536, OutputBufferSize: 65536,
	})
}
