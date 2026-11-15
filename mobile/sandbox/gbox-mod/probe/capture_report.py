"""Read only CageGBoxProbe log entries; save the latest intact report, never raw logs."""
import argparse
import json
from pathlib import Path
import subprocess
from compare_reports import parse_log_report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', type=Path, required=True)
    parser.add_argument('--serial', required=True)
    parser.add_argument('--port', type=int, default=5037)
    parser.add_argument('--since', required=True, help='ADB logcat timestamp or bounded line count')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists(): raise FileExistsError(args.output)
    result = subprocess.run([str(args.adb), '-P', str(args.port), '-s', args.serial,
        'logcat', '-d', '-v', 'threadtime', '-T', args.since, '-s', 'CageGBoxProbe:I', '*:S'],
        capture_output=True, timeout=20)
    if result.returncode: raise RuntimeError('ADB report read failed; raw output withheld')
    report = parse_log_report(result.stdout.decode('utf-8', errors='strict'))
    if report.get('package') != 'io.github.leexeo.cage.gboxprobe':
        raise ValueError('Unexpected report package')
    with args.output.open('x', encoding='utf-8') as stream:
        json.dump(report, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
    print(json.dumps({'saved': str(args.output), 'complete': True, 'run': report['run'],
                     'networkMetadataVersion': report.get('networkMetadataVersion')}))


if __name__ == '__main__': main()
