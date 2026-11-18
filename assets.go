// Package agentvm holds the files of this repository the binary embeds.
package agentvm

import "embed"

// WindowsLocalDesktopScripts contains the controller-side scripts used to
// verify and import the official package selected in the local workbench.
//
//go:embed tools/windows-local/Import-CageLocalDesktop.ps1 scripts/guest-os/claude-desktop-windows.ps1
var WindowsLocalDesktopScripts embed.FS

// CageVersion is the default version for source builds without linker flags.
// Release builds may override internal/version.Version explicitly.
//
//go:embed VERSION
var CageVersion string

// SetupScript provisions the base VM: `agent-vm setup` runs it in the guest,
// after the choices as export lines.
//
//go:embed agent-vm.setup.sh
var SetupScript string

// The license of agent-vm, the notice about third_party/, and the licenses of
// what the binary is built from (scripts/licenses): `agent-vm licenses`.
var (
	//go:embed LICENSE
	License string
	//go:embed NOTICE
	Notice string
	//go:embed THIRD_PARTY_LICENSES
	ThirdPartyLicenses string
)
