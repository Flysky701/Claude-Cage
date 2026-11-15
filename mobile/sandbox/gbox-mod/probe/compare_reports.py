"""Read saved probe JSON/logcat and compare observations. Never controls devices."""
import argparse
import json
from pathlib import Path


def load_report(path):
    text = Path(path).read_text(encoding='utf-8-sig')
    try:
        report = json.loads(text)
        if isinstance(report, dict) and report.get('schemaVersion') == 1:
            if not report.get('complete'):
                raise ValueError(f'Probe did not complete: {path}')
            return report
    except json.JSONDecodeError:
        pass
    runs, last = {}, None
    for line in text.splitlines():
        if 'REPORT|' in line:
            fields = line[line.index('REPORT|'):].split('|', 3)
            if len(fields) != 4:
                continue
            _, run, section, encoded = fields
            try:
                value = json.loads(encoded)
            except json.JSONDecodeError:
                value = encoded
            runs.setdefault(run, {})[section] = value
        elif 'END|' in line:
            run = line[line.index('END|') + 4:].strip()
            if runs.get(run, {}).get('complete') is True:
                last = runs[run]
    if last is None:
        raise ValueError(f'No completed probe report found: {path}')
    return last


def value(item):
    return item.get('value') if isinstance(item, dict) and item.get('status') == 'OK' else None


def all_values(tree, key):
    if isinstance(tree, dict):
        if key in tree:
            yield tree[key]
        for nested in tree.values():
            yield from all_values(nested, key)
    elif isinstance(tree, list):
        for nested in tree:
            yield from all_values(nested, key)


def has_api_error(tree, allow_security=False):
    if isinstance(tree, dict):
        if tree.get('status') == 'ERROR' and not (allow_security and tree.get('type') == 'SecurityException'):
            return True
        return any(has_api_error(v, allow_security) for v in tree.values())
    return isinstance(tree, list) and any(has_api_error(v, allow_security) for v in tree)


def getter_present(item):
    if not isinstance(item, dict):
        return False
    if item.get('status') == 'ERROR':
        return isinstance(item.get('type'), str)
    return item.get('status') in ('OK', 'EMPTY', 'NULL') and 'value' in item


def native_property_valid(item):
    return (isinstance(item, dict) and isinstance(item.get('value'), str)
            and ((item.get('status') == 'EMPTY' and item['value'] == '')
                 or (item.get('status') == 'OK' and item['value'] != '')))


def native_interfaces(report):
    native = report.get('nativeInProcess', {})
    entries = value(native.get('interfaces')) if native.get('status') == 'OK' else None
    return entries if isinstance(entries, list) and all(isinstance(name, str) and name for name in entries) else None


def missing_sim(report, require_extra=False):
    missing = []
    sim = report.get('sim', {})
    for name in ('defaultState', 'simCountry', 'simOperator', 'simOperatorName',
                 'networkCountry', 'networkOperator', 'networkOperatorName', 'defaultSubscription',
                 'dataSubscription', 'voiceSubscription', 'smsSubscription', 'activeSubscriptions'):
        if not getter_present(sim.get(name)):
            missing.append('sim.' + name)
    slots = sim.get('slots')
    for index in (0, 1):
        if not isinstance(slots, list) or not any(s.get('slot') == index and getter_present(s.get('state')) for s in slots):
            missing.append(f'sim.slots[{index}]')
    props = report.get('nativeSubprocess', {}).get('properties', {})
    for key in ('gsm.sim.operator.iso-country', 'gsm.sim.operator.alpha', 'gsm.sim.operator.numeric',
                'gsm.operator.iso-country', 'gsm.operator.alpha', 'gsm.operator.numeric'):
        if not getter_present(props.get(key)):
            missing.append('nativeSubprocess.properties.' + key)
        native = report.get('nativeInProcess', {})
        if native.get('status') != 'OK' or not native_property_valid(native.get('properties', {}).get(key)):
            missing.append('nativeInProcess.properties.' + key)
        if require_extra:
            for api in ('legacyRead', 'callback'):
                if not isinstance(native.get('propertyApis', {}).get(api, {}).get(key), str):
                    missing.append('nativeInProcess.propertyApis.' + api + '.' + key)
    return missing


def interface_reading_valid(reading):
    # LinkProperties.getInterfaceName() explicitly permits null. A measured NULL
    # differs from a missing getter, an absent capability object, or an API error.
    # https://developer.android.com/reference/android/net/LinkProperties#getInterfaceName()
    return isinstance(reading, dict) and (
        reading.get('status') in ('OK', 'EMPTY') and isinstance(reading.get('value'), str)
        or reading.get('status') == 'NULL' and 'value' in reading and reading['value'] is None
    )


def incomplete_network(report, require_link_callback=False):
    missing = []
    network = report.get('network', {})
    def caps_valid(caps):
        return isinstance(caps, dict) and all(isinstance(caps.get(k), bool) for k in ('vpn', 'notVpn'))
    def network_valid(entry):
        return isinstance(entry, dict) and caps_valid(value(entry.get('capabilities'))) and interface_reading_valid(entry.get('interface'))
    if not network_valid(value(network.get('active'))):
        missing.append('network.active')
    all_networks = value(network.get('allNetworks'))
    if not isinstance(all_networks, list) or not all(network_valid(entry) for entry in all_networks):
        missing.append('network.allNetworks')
    interfaces = value(network.get('interfaces'))
    if not isinstance(interfaces, list) or not all(isinstance(entry, dict) and isinstance(entry.get('name'), str) for entry in interfaces):
        missing.append('network.interfaces')
    callback = report.get('networkCallback', {})
    events = callback.get('events')
    if callback.get('status') != 'OK' or not isinstance(events, list) or not events or not all(caps_valid(entry) for entry in events):
        missing.append('networkCallback.events')
    if require_link_callback:
        links = callback.get('linkProperties')
        if not isinstance(links, list) or not links or not all(isinstance(entry, dict) and interface_reading_valid(entry.get('interface')) for entry in links):
            missing.append('networkCallback.linkProperties')
    if native_interfaces(report) is None:
        missing.append('nativeInProcess.interfaces')
    return missing


def interface_names(report):
    names = []
    for tree in (report.get('network', {}), report.get('networkCallback', {})):
        for reading in all_values(tree, 'interface'):
            name = value(reading)
            if isinstance(name, str):
                names.append(name)
    entries = value(report.get('network', {}).get('interfaces'))
    if isinstance(entries, list):
        names.extend(entry['name'] for entry in entries if isinstance(entry, dict) and isinstance(entry.get('name'), str))
    names.extend(native_interfaces(report) or [])
    return sorted(set(names))


def number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def utc_delta(measured, before, after):
    if not all(number(v) for v in (measured, before, after)) or after < before:
        return None
    return max(before - measured, measured - after, 0)


def outcome(status, **details):
    return {'status': status, **details}


def sim_signals(report):
    sim = report.get('sim', {})
    signals = {}
    for name in ('simCountry', 'simOperator', 'simOperatorName', 'networkCountry', 'networkOperator', 'networkOperatorName'):
        field = value(sim.get(name))
        if field:
            signals[name] = field
    if value(sim.get('defaultState')) not in (None, 0, 1):
        signals['defaultState'] = value(sim['defaultState'])
    for entry in sim.get('slots', []):
        if value(entry.get('state')) not in (None, 0, 1):
            signals[f"slot{entry['slot']}"] = value(entry['state'])
    for name in ('defaultSubscription', 'dataSubscription', 'voiceSubscription', 'smsSubscription'):
        if value(sim.get(name)) is True:
            signals[name] = True
    if value(sim.get('activeSubscriptions')):
        signals['activeSubscriptionCount'] = len(value(sim['activeSubscriptions']))
    for source in ('nativeSubprocess', 'nativeInProcess'):
        for name, prop in report.get(source, {}).get('properties', {}).items():
            measured = value(prop)
            if name.startswith('gsm.') and isinstance(measured, str) and measured.strip(', '):
                signals[source + '.' + name] = measured
    for api in ('legacyRead', 'callback'):
        for name, measured in report.get('nativeInProcess', {}).get('propertyApis', {}).get(api, {}).items():
            if name.startswith('gsm.') and isinstance(measured, str) and measured.strip(', '):
                signals['nativeInProcess.' + api + '.' + name] = measured
    return signals


def property_api_controls(outer, guest, required):
    if not required:
        return outcome('NOT_MEASURED_LEGACY_REPORT', required=False)
    missing, changed, no_signal = [], [], []
    controls = ('persist.radio.multisim.config', 'telephony.active_modems.max_count', 'ro.build.version.sdk')
    observations = {}
    for label, report in (('outer', outer), ('guest', guest)):
        data = report.get('nativeInProcess', {}).get('propertyApis', {})
        if data.get('callbacksValid') is not True:
            missing.append(label + '.callbacksValid')
        observations[label] = data.get('controls', {})
        for key in controls:
            reading = observations[label].get(key)
            # A missing optional hardware property is a recorded result, not proof of filtering.
            if not isinstance(reading, list) or len(reading) != 3 or not all(
                isinstance(v, str) or v == {'error': 'MissingProperty'} for v in reading
            ):
                missing.append(label + '.controls.' + key)
        if label == 'outer':
            for api in ('legacyRead', 'callback'):
                if not any(k.startswith('gsm.') and isinstance(v, str) and v.strip(', ')
                           for k, v in data.get(api, {}).items()):
                    no_signal.append(api)
    for key in controls:
        if key in observations['outer'] and key in observations['guest'] and observations['outer'][key] != observations['guest'][key]:
            changed.append(key)
    return outcome('FAIL_UNRELATED_PROPERTY_CHANGED' if changed else
                   'INCONCLUSIVE_MISSING_OR_INVALID_READINGS' if missing else
                   'PARTIAL_NO_OUTER_API_SIM_SIGNAL' if no_signal else 'PASS_FOR_RECORDED_PATHS',
                   required=True, missing=missing, changedControls=changed,
                   outerApiWithoutSimSignal=no_signal, controls=observations,
                   controlApiOrder=['get', 'legacyRead', 'callback'])


def compare(outer, guest, expected_zone, outer_after=None, guest_after=None, expected_offset=540):
    if outer.get('package') != guest.get('package'):
        raise ValueError('Outer and guest package names differ')
    capacity_fields = ('activeModemCount', 'phoneCount')
    source_sim, guest_sim = sim_signals(outer), sim_signals(guest)
    extra_apis = any('propertyApis' in report.get('nativeInProcess', {}) for report in (outer, guest))
    guest_missing_sim, outer_missing_sim = missing_sim(guest, extra_apis), missing_sim(outer, extra_apis)
    sim_error = any(has_api_error({key: reading for key, reading in report.get('sim', {}).items() if key not in capacity_fields}) or has_api_error({
        source + '.' + key: reading for source in ('nativeSubprocess', 'nativeInProcess')
        for key, reading in report.get(source, {}).get('properties', {}).items() if key.startswith('gsm.')
    }) for report in (outer, guest))
    sim = outcome('FAIL_VISIBLE_SIM_SIGNAL' if guest_sim else
                  'INCONCLUSIVE_MISSING_READINGS' if guest_missing_sim or outer_missing_sim else
                  'INCONCLUSIVE_API_ERRORS' if sim_error else
                  'N/A_NO_OUTER_SIM_SIGNAL' if not source_sim else
                  'PARTIAL_NO_OUTER_NATIVE_SIM_SIGNAL' if not any(name.startswith('nativeInProcess.') for name in source_sim) else
                  'PASS_FOR_RECORDED_PATHS',
                  outerSignalFields=list(source_sim), guestSignalFields=list(guest_sim),
                  missingOuter=outer_missing_sim, missingGuest=guest_missing_sim,
                  readPhoneStateGranted={'outer': outer.get('permissions', {}).get('readPhoneState'),
                                         'guest': guest.get('permissions', {}).get('readPhoneState')})
    outer_count = {key: value(outer.get('sim', {}).get(key)) for key in capacity_fields}
    guest_count = {key: value(guest.get('sim', {}).get(key)) for key in outer_count}
    valid_counts = all(isinstance(v, int) and not isinstance(v, bool) and v >= 0 for v in [*outer_count.values(), *guest_count.values()])
    # AOSP API32: getPhoneCount delegates to getActiveModemCount; multi-SIM configuration
    # and device voice/SMS/data resources determine this count, not SIM insertion state.
    # Retain the legacy slotCount key, but never grade these capacity values as SIM shielding.
    slots = outcome('OBSERVED_HARDWARE_CAPACITY' if valid_counts else 'INCONCLUSIVE_CAPACITY_READINGS',
                    outer=outer_count, guest=guest_count, simIsolationCriterion=False,
                    meaning='Configured modem capacity; neither SIM presence nor capacity hiding is established by these counts',
                    semanticsSource='AOSP API32 TelephonyManager.getPhoneCount/getActiveModemCount')
    zone = guest.get('timezone', {})
    in_process = guest.get('nativeInProcess', {})
    browser = value(guest.get('webview')) or {}
    require_first_script = any(report.get('probeVersion', 0) >= 6 for report in (outer, guest))
    first_script = browser.get('firstScript') if isinstance(browser.get('firstScript'), dict) else {}
    prop_zone = value(guest.get('nativeSubprocess', {}).get('properties', {}).get('persist.sys.timezone'))
    zones = {'java': value(zone.get('javaId')), 'icu': value(zone.get('icuId')),
             'webview': browser.get('timezone'), 'childProperty': prop_zone,
             'nativeProperty': value(in_process.get('properties', {}).get('persist.sys.timezone'))}
    if extra_apis:
        for api in ('legacyRead', 'callback'):
            reading = in_process.get('propertyApis', {}).get(api, {}).get('persist.sys.timezone')
            zones['nativeProperty.' + api] = reading if isinstance(reading, str) else None
    if require_first_script:
        zones['webviewFirstScript'] = first_script.get('timezone')
    missing = [key for key, zone_id in zones.items() if not zone_id]
    wrong = [key for key, zone_id in zones.items() if zone_id and zone_id != expected_zone]
    environment = zone.get('environmentTZ')
    environment_zone = value(environment)
    if not getter_present(environment) or environment.get('status') == 'ERROR':
        missing.append('environmentTZ')
    elif environment.get('status') == 'OK':
        if not isinstance(environment_zone, str):
            missing.append('environmentTZ')
        elif environment_zone != expected_zone:
            wrong.append('environmentTZ')
    java_offset = value(zone.get('javaOffsetMinutes'))
    offsets = {'java': java_offset, 'icu': value(zone.get('icuOffsetMinutes')), 'webview': browser.get('offsetMinutes')}
    if require_first_script:
        offsets['webviewFirstScript'] = first_script.get('offsetMinutes')
    native_deltas = {}
    if in_process.get('status') != 'OK':
        missing.append('nativeInProcess')
    for phase, refreshed in (('initialTime', False), ('afterTzsetTime', True)):
        reading = in_process.get(phase, {})
        measured = value(reading)
        if not isinstance(measured, dict) or measured.get('explicitTzset') is not refreshed:
            missing.append('nativeInProcess.' + phase)
            continue
        seconds = measured.get('offsetSeconds')
        offsets['nativeInProcess.' + phase] = seconds / 60 if number(seconds) else None
        epoch = measured.get('epochSeconds')
        delta = utc_delta(epoch * 1000 if number(epoch) else None, reading.get('javaBeforeEpochMillis'), reading.get('javaAfterEpochMillis'))
        if delta is None:
            missing.append('nativeInProcess.' + phase + '.utcComparison')
        else:
            native_deltas[phase] = delta
    if guest.get('timezoneProbePreviouslyRefreshed') is not False or in_process.get('initialTimeRetainedFromEarlierCapture') is not False:
        missing.append('freshJavaAndWebViewContextBeforeExplicitTzset')
    native_date = value(guest.get('nativeSubprocess', {}).get('date'))
    epoch_delta = None
    try:
        _, native_offset, seconds = native_date.split('|')
        sign = -1 if native_offset.startswith('-') else 1
        offsets['nativeSubprocess'] = sign * (int(native_offset[1:3]) * 60 + int(native_offset[3:5]))
        native = guest.get('nativeSubprocess', {})
        epoch_delta = utc_delta(int(seconds) * 1000, native.get('javaDateBeforeEpochMillis', guest.get('epochMillis')),
                               native.get('javaDateAfterEpochMillis', guest.get('epochMillis')))
    except (AttributeError, ValueError, TypeError):
        missing.append('nativeSubprocess')
    for key, measured in offsets.items():
        if not number(measured):
            missing.append(key + 'Offset')
        elif measured != expected_offset:
            wrong.append(key + 'Offset')
    browser_reading = guest.get('webview', {})
    browser_delta = utc_delta(browser.get('epochMillis'), browser_reading.get('javaRequestEpochMillis', guest.get('epochMillis')),
                              browser_reading.get('javaReceivedEpochMillis', guest.get('epochMillis')))
    if epoch_delta is None:
        missing.append('nativeUtcComparison')
    if browser_delta is None:
        missing.append('webviewUtcComparison')
    first_script_delta = utc_delta(first_script.get('epochMillis'), browser_reading.get('javaRequestEpochMillis'),
                                   browser_reading.get('javaReceivedEpochMillis')) if require_first_script else None
    if require_first_script and first_script_delta is None:
        missing.append('webviewFirstScriptUtcComparison')
    utc_tolerance = 30000
    utc_wrong = [name for name, delta in [('nativeSubprocess', epoch_delta), ('webview', browser_delta), ('webviewFirstScript', first_script_delta),
                                        *[('nativeInProcess.' + phase, delta) for phase, delta in native_deltas.items()]]
                 if delta is not None and delta > utc_tolerance]
    timezone = outcome('FAIL_INCONSISTENT_UTC' if utc_wrong else
                       'FAIL_INCONSISTENT_TIMEZONE' if wrong else
                       'INCONCLUSIVE_MISSING_READINGS' if missing else
                       'N/A_OUTER_ALREADY_EXPECTED_ZONE' if value(outer.get('timezone', {}).get('javaId')) == expected_zone else
                       'PASS_FOR_RECORDED_PATHS', expected=expected_zone, ids=zones, offsets=offsets,
                       missing=missing, mismatch=wrong, expectedOffsetMinutes=expected_offset,
                       environmentTZ=environment_zone,
                       environmentTZStatus=environment.get('status') if isinstance(environment, dict) else 'MISSING',
                       nativeInProcessEpochDeltaMillis=native_deltas,
                       diagnosticChildElf=guest.get('nativeSubprocess', {}).get('diagnosticChildElf', {'status': 'NOT_MEASURED'}),
                       diagnosticChildElfScope='Only the diagnostic child main ELF; not proof of date/getprop ISA or absence of translated payloads',
                       subprocessEpochDeltaMillis=epoch_delta, webviewEpochDeltaMillis=browser_delta,
                       firstScriptRequired=require_first_script, firstScriptEpochDeltaMillis=first_script_delta,
                       utcMismatch=utc_wrong, utcToleranceMillis=utc_tolerance,
                       utcScope='Java versus local WebView/libc/subprocess only; does not establish absolute remote time',
                       nativeScope=('get/read/read_callback' if extra_apis else '__system_property_get')
                                   + ', time/localtime_r before and after explicit tzset; direct syscalls not covered')
    outer_vpn = any(x is True for x in all_values(outer.get('network', {}), 'vpn'))
    outer_vpn |= any(x is True for x in all_values(outer.get('networkCallback', {}), 'vpn'))
    guest_vpn = any(x is True for x in all_values(guest.get('network', {}), 'vpn'))
    guest_vpn |= any(x is True for x in all_values(guest.get('networkCallback', {}), 'vpn'))
    guest_not_vpn_false = any(x is False for tree in (guest.get('network', {}), guest.get('networkCallback', {}))
                              for x in all_values(tree, 'notVpn'))
    names = interface_names(guest)
    tunnel_names = [name for name in names if name.startswith(('tun', 'tap', 'wg', 'ppp'))]
    callback_status = guest.get('networkCallback', {}).get('status')
    missing_guest_network, missing_outer_network = incomplete_network(guest, require_link_callback=True), incomplete_network(outer)
    vpn_error = has_api_error(guest.get('network', {})) or has_api_error(guest.get('networkCallback', {})) or has_api_error(in_process.get('interfaces', {}))
    native_outer_tunnels = [name for name in native_interfaces(outer) or [] if name.startswith(('tun', 'tap', 'wg', 'ppp'))]
    vpn = outcome('FAIL_VPN_OBSERVABLE' if guest_vpn or tunnel_names or guest_not_vpn_false else
                  'INCONCLUSIVE_API_OR_CALLBACK' if vpn_error or missing_guest_network or missing_outer_network else
                  'N/A_NO_OUTER_VPN_SIGNAL' if not outer_vpn else
                  'PARTIAL_NO_OUTER_NATIVE_VPN_SIGNAL' if not native_outer_tunnels else
                  'PASS_FOR_RECORDED_PATHS',
                  outerVpnVisible=outer_vpn, guestVpnVisible=guest_vpn, tunnelLikeInterfaces=tunnel_names,
                  guestNotVpnCapabilityFalse=guest_not_vpn_false, observedInterfaceNames=names,
                  callbackStatus=callback_status, missingOuter=missing_outer_network, missingGuest=missing_guest_network,
                  nativeOuterTunnelInterfaces=native_outer_tunnels,
                  nativeScope='getifaddrs interface names only; direct syscall/netlink paths not covered',
                  actualTrafficEnforcement='NOT_TESTED_BY_THIS_OFFLINE_COMPARISON')
    left, right = value(outer.get('marker')), value(guest.get('marker'))
    if not left or not right:
        markers = outcome('NOT_TESTED_BOTH_MARKERS_REQUIRED')
    elif left == right:
        markers = outcome('FAIL_SHARED_MARKER')
    elif outer_after is None or guest_after is None:
        markers = outcome('PARTIAL_DISTINCT_MARKERS_PERSISTENCE_NOT_CHECKED')
    else:
        missing_evidence = []
        runs = [item.get('run') for item in (outer, guest, outer_after, guest_after)]
        sessions = [item.get('processSessionId') for item in (outer, guest, outer_after, guest_after)]
        if not all(isinstance(run, str) and run for run in runs) or len(set(runs)) != 4:
            missing_evidence.append('four_independent_runs_required')
        if not all(isinstance(session, str) and session for session in sessions) or len(set(sessions)) != 4:
            missing_evidence.append('four_independent_process_sessions_required')
        for name, before, after in (('outer', outer, outer_after), ('guest', guest, guest_after)):
            if after.get('package') != before.get('package'):
                missing_evidence.append(name + '_after_package_mismatch')
            if not after.get('complete'):
                missing_evidence.append(name + '_after_incomplete')
            before_start, after_start = before.get('processStartElapsedRealtimeMillis'), after.get('processStartElapsedRealtimeMillis')
            if not all(number(v) and v >= 0 for v in (before_start, after_start)) or before_start == after_start:
                missing_evidence.append(name + '_process_restart_not_proven')
            before_time, after_time = before.get('epochMillis'), after.get('epochMillis')
            if not all(number(v) for v in (before_time, after_time)) or after_time <= before_time:
                missing_evidence.append(name + '_after_not_later')
        persisted = value(outer_after.get('marker')) == left and value(guest_after.get('marker')) == right
        markers = outcome('INCONCLUSIVE_RESTART_EVIDENCE' if missing_evidence else
                          'PASS_DISTINCT_AND_PERSISTENT' if persisted else 'FAIL_MARKER_CHANGED',
                          missingEvidence=missing_evidence,
                          scope='One SharedPreferences marker per app instance after fresh process starts')
    machines = {}
    for name, report in (('outer', outer), ('guest', guest)):
        native = report.get('nativeInProcess', {})
        elf = value(native.get('processMainElf'))
        valid_elf = (isinstance(elf, dict) and elf.get('magicOk') is True and elf.get('elfClass') in (1, 2)
                     and elf.get('byteOrder') in (1, 2) and isinstance(elf.get('eMachine'), int) and elf['eMachine'] > 0)
        machines[name] = outcome('MEASURED' if native.get('status') == 'OK' and native.get('compiledAbi') == 'arm64-v8a' and valid_elf else
                                'INCONCLUSIVE_NATIVE_ARCHITECTURE', compiledAbi=native.get('compiledAbi'), processMainElf=elf)
    return {'schemaVersion': 1, 'assessment': 'SCOPED_OBSERVATIONS_NOT_FULL_ACCEPTANCE',
            'sim': sim, 'slotCount': slots, 'timezone': timezone, 'vpnVisibility': vpn, 'privateData': markers,
            'nativeArchitecture': machines,
            'nativePropertyApiControls': property_api_controls(outer, guest, extra_apis),
            'nativeCoverage': 'Recorded libc calls only; direct native syscall/netlink paths remain untested',
            'accountLogin': 'NOT_TESTED_BY_PROBE', 'claudeLogin': 'NOT_TESTED_BY_PROBE'}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--outer', type=Path, required=True)
    parser.add_argument('--guest', type=Path, required=True)
    parser.add_argument('--outer-after', type=Path)
    parser.add_argument('--guest-after', type=Path)
    parser.add_argument('--expected-zone', default='Asia/Tokyo')
    parser.add_argument('--expected-offset-minutes', type=int, default=540)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = compare(load_report(args.outer), load_report(args.guest), args.expected_zone,
                     load_report(args.outer_after) if args.outer_after else None,
                     load_report(args.guest_after) if args.guest_after else None, args.expected_offset_minutes)
    encoded = json.dumps(result, ensure_ascii=False, indent=2)
    if args.output:
        args.output.write_text(encoded, encoding='utf-8')
    print(encoded)


if __name__ == '__main__':
    main()
