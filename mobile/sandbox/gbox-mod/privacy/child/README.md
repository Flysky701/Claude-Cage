# Child property policy

`Cage-Child-Property-Probe-01.apk` is an independent, disposable probe. It has no
network or account permissions and changes only its own `ProcessBuilder`
environment. Device execution belongs to the coordinating MuMu actor.

The x86_64 and arm64-v8a preload libraries intercept the ordinary Bionic property `get`,
`read`, and `read_callback` APIs. It does not special-case command lines, rewrite
`getprop` output, write the shared property area, or modify fork/exec. The probe
compares raw values in private parent/child pipes and writes only booleans,
counts, fixed stages, and ELF/loaded-state diagnostics to its result JSON.

SIM policy: `gsm.sim.state=ABSENT`; SIM and network operator alpha/numeric/country
strings empty; `gsm.operator.isroaming=false`; `gsm.current.phone-type=0`.
Timezone property: `persist.sys.timezone=Asia/Tokyo`. Device-capacity properties
`persist.radio.multisim.config` and `telephony.active_modems.max_count` are
unchanged. The library does not own the parent's `TZ` lifecycle.

The x86_64 library checks the executable's actual ELF machine, the existing
MuMu fingerprint suffix, nonempty hardware/board properties, SDK 31/32 and
`libnb.so` native bridge. The Android 16 arm64-v8a library instead requires an
actual AArch64 executable, raw system SDK 36, an absent/disabled native bridge,
and the explicit `android16-arm64` child profile. Both activate only for
configured selected guest scopes. Existing preload libraries are retained.
The independent probe includes an existing-library sentinel, an unselected
scope, a disabled policy, and a restored environment comparison. It reads the
ELF header and observes a constructor marker separately for the self-authored
reader, system `getprop`, and system `date`.

Build locally:

```powershell
python mobile/sandbox/gbox-mod/privacy/child/fetch_ndk_x86.py
python mobile/sandbox/gbox-mod/privacy/child/build.py
```

The first command obtains only five missing link inputs from the official NDK
r27d ZIP using verified bounded byte ranges and ZIP member CRCs. Existing headers
and compiler are reused. After compilation, `--finalize-only` resumes packaging
and signing without recompiling. The probe report is
`files/latest-child-property-report.json`, log tag `CageChildProbe`.

The standalone probe command above remains x86_64-only. The GBox module's
`build(work, context)` entry builds both x86_64 and arm64-v8a libraries. Both
target API 28; the arm64-v8a ELF load segments use 16 KiB alignment. The GBox
sample's target SDK is unchanged. Libraries are stored as APK assets; no new
top-level native-library ABI is added. A successful independent probe still
requires a real GBox child-loading check before claiming coverage there.

The historical MuMu result `mumu/child-property-probe01-result.json` is PASS:
all three APIs read ten expected values, the six operator fields have positive
controls, actual reader/getprop/date ELF machine is 62, existing preload and
capacity values are preserved, and unselected/disabled/restored views equal the
baseline. No related crash was observed in that run. This evidence does not
validate the newly compiled libraries or the Android 16 path.

`ChildPolicy.activate(Context, sim, timezone, zone)` now has its independent
probe gate enabled. Its prepared GBox path
requires the existing completed NativeCompat guard for MuMu. For Android 16 it
checks SDK 36, 64-bit execution, and the actual ELF headers of the parent,
`/system/bin/sh`, `getprop`, and `date`; the child repeats its own raw system
SDK/native-bridge checks. Both paths check current guest
identity, reads assets from the original VLite host Context, extracts an
immutable library into host code cache, then snapshots and restores `LD_PRELOAD`
and its own configuration variables. It does not change unselected processes.

Not covered: 32-bit or unsupported-profile executables, statically linked programs, direct property
area reads, explicit child environments that drop the inherited policy, or
native VPN/interface queries in child processes. This is process-local property
presentation, not a complete native isolation engine.

Primary API reference: [AOSP Bionic system property API](https://android.googlesource.com/platform/bionic/+/50080a2/libc/include/sys/system_properties.h).
Toolchain source: [Android NDK r27d release](https://github.com/android/ndk/releases/tag/r27d).

The callback keeps the original opaque serial token, matching the unmodified
direct serial/wait APIs and the successfully tested Probe 01 behavior. Although
[Android 12 Bionic internally stores a length in that token](https://raw.githubusercontent.com/aosp-mirror/platform_bionic/android12-release/libc/system_properties/system_properties.cpp),
the public callback receives its value as a NUL-terminated string. Only the
explicit `get`/`read` length return is changed. Code depending on the private
serial bit layout is not covered. No property update, wakeup or shared state is
faked. A briefly considered serial-length change was withdrawn before GBox
integration so cached token comparisons remain consistent.

Android 12 libcore's default `ProcessBuilder` keeps its environment field null;
the JNI child launcher then uses `execvp`, inheriting current native `environ`.
`Os.setenv` therefore covers that default path. Calling `.environment()` instead
clones the `ProcessEnvironment` class's earlier cached map, which can omit later
native changes. This implementation does not modify that Java cache or override
explicit child environments. `System.getenv(name)` is live on Android, while
its no-argument map uses the cached view. Source copies and line references are
under the build directory's `child-probe/libcore-reference`.

Privacy 06 reached ChildPolicy but its initial Java cache comparisons could
silently reject activation. The original VLite device service contains a
reflection path that rewrites `Build` static fields for a guest. The next
integration relies on the already completed NativeCompat native profile check
instead: `gate.cpp` checks the exact raw fingerprint, hardware, board, native
bridge, SDK and mapped host ART, and `NativeCompat.isActive()` additionally
requires `nativeVerify()` success. SDK, 64-bit execution and selected guest
identity checks remain. Java cache matches are logged only as booleans, with no
values. The Android 16 addition preserves the existing x86 profile conditions;
both libraries independently check their actual executable ISA and raw
properties on load. Child scope remains Claude and the two owned probe package
names; this does not change Google authentication processes or their results.

## Android 16 validation boundary

Follow-up phone evidence (2026-11-15): Test07 and three fresh guest starts on
Xiaomi 15 Pro/API36 produced hidden SIM properties and Tokyo/+540 in the
existing default-environment getprop/date subprocess probe, with the original
guest marker retained. This validates those concrete subprocess paths only;
the standalone offline checks below remain separate evidence. Explicit/cached
child environments and child VPN interface enumeration are still not covered.

The 2026-11-15 implementation was compiled offline on Windows for both ABIs
with warnings treated as errors. The Java class was also compiled against the
Android API JAR with a minimal `GuestPrivacy` dependency stub; that check covers
syntax/API references, not VLite integration. The initial offline module work
did not operate any device or application data; subsequent integration evidence
is listed above. It does not establish enabled/disabled controls or restoration.
macOS and Linux build/runtime execution were not performed; the Android ABI
assets and their package paths are shared and unchanged across host platforms.

Required device evidence includes first-start child activation, all three
property APIs, system `getprop`/`date`, enabled/disabled policy controls,
preservation of an existing preload, and return to the original environment.
Explicit or previously cached `ProcessBuilder` environment maps remain outside
coverage. The older libcore observation above is not a new Android 16 runtime
verification. VPN interface queries in children are also outside this property
module; they must not be reported as covered by a SIM/timezone pass.
