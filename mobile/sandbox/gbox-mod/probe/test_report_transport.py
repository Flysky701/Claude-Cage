"""Prevent Android log truncation and missing chunks from becoming valid evidence."""
import base64
import hashlib
import json
import unittest
from compare_reports import parse_log_report, validate_report


RUN = '11111111-1111-1111-1111-111111111111'


def fixture(run=RUN):
    return dict(schemaVersion=1, complete=True, run=run, network={'fixture': '测试' * 5000},
                networkCallback={}, sim={}, timezone={}, webview={}, nativeSubprocess={}, nativeInProcess={})


def lines(report=None):
    report = report or fixture()
    data = json.dumps(report, ensure_ascii=False).encode('utf-8')
    parts = [data[i:i + 1800] for i in range(0, len(data), 1800)]
    rows = [f"REPORT2|{report['run']}|{i}|{len(parts)}|{base64.b64encode(part).decode()}" for i, part in enumerate(parts)]
    return rows + [f"END2|{report['run']}|{len(parts)}|{hashlib.sha256(data).hexdigest()}"]


class TransportTest(unittest.TestCase):
    def rejects(self, rows):
        with self.assertRaises(ValueError): parse_log_report('\n'.join(rows))

    def test_large_multibyte_round_trip(self):
        rows = lines()
        self.assertTrue(all(len(row.encode()) < 3000 for row in rows))
        self.assertEqual(parse_log_report('\n'.join('timestamp tag: ' + row for row in rows)), fixture())

    def test_missing_chunk(self): self.rejects(lines()[1:])
    def test_missing_end(self): self.rejects(lines()[:-1])
    def test_duplicate_chunk(self): self.rejects(lines()[:1] + lines())
    def test_truncated_chunk(self): self.rejects([lines()[0][:-20]] + lines()[1:])
    def test_wrong_digest(self): self.rejects(lines()[:-1] + [lines()[-1][:-64] + '0' * 64])
    def test_count_conflict(self):
        rows = lines(); fields = rows[0].split('|', 4)
        fields[3] = str(int(fields[3]) - 1)
        self.rejects(['|'.join(fields)] + rows[1:])

    def test_latest_broken_run_does_not_select_old_pass(self):
        newer = lines(fixture('22222222-2222-2222-2222-222222222222'))
        self.rejects(lines() + newer[:-1])

    def test_old_truncated_section_rejected(self):
        report = fixture(); report['network'] = '{"active":'
        with self.assertRaises(ValueError): validate_report(report)

    def test_valid_legacy_format(self):
        report = fixture(); report['network'] = {}
        rows = [f'REPORT|{RUN}|{key}|' + json.dumps(value) for key, value in report.items()]
        rows.append(f'END|{RUN}')
        self.assertEqual(parse_log_report('\n'.join(rows)), report)


if __name__ == '__main__': unittest.main()
