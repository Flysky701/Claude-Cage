export function windowsLocalAccount(status) {
  return status?.guest_system === "windows-local" && status.windows_local_prototype === true;
}

// Windows remote and native-account workbenches advertise supported operations.
export function guestCapability(status, name) {
  return (!windowsLocalAccount(status) && status?.guest_system !== "windows-remote") ||
    status.guest_capabilities?.available?.[name] === true;
}
