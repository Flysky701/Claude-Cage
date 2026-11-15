package windowslite

import (
	_ "embed"
	"encoding/json"
)

type ComponentArtifact struct {
	Version string `json:"version"`
	File    string `json:"file"`
	URL     string `json:"url"`
	SHA256  string `json:"sha256"`
}

//go:embed dependencies.json
var dependencyManifest []byte

// Dependency pins are shipped with the app, never supplied by an HTTP caller.
func Dependency(name string) ComponentArtifact {
	var artifacts map[string]ComponentArtifact
	if err := json.Unmarshal(dependencyManifest, &artifacts); err != nil {
		panic(err)
	}
	return artifacts[name]
}
