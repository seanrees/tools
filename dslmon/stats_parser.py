#!/usr/bin/env python

from sys import stdin
import re
import time

class StatsParser:
    def _match(self, pattern, line, attrs, key):
        m = re.search(pattern, line)
        if m:
            attrs[key] = int(m.group(1))
            return True

        return False

    def parse_tones(self, line):
        tone_chars = line.split(":")[1].strip()
        tones = []
        for c in tone_chars:
            if c == ' ': continue
            tones += [int(c, 16)]

        return tones

    def parse_linedata_near(self, stats, lines):
        for line in lines:
            if (self._match("noise margin downstream: (-?\d+) db", line, stats, "noise_margin_downstream_db")):
                continue
            elif (self._match("output power upstream: (-?\d+) db", line, stats, "output_power_upstream_db")):
                continue
            elif (self._match("attenuation downstream: (-?\d+) db", line, stats, "attenuation_downstream_db")):
                continue
            elif (re.match("tone.*", line)):
                stats['tones_downstream'] += self.parse_tones(line)

    # TODO: merge this into parse_linedata_near
    def parse_linedata_far(self, stats, lines):
        for line in lines:
            if (self._match("noise margin upstream: (-?\d+) db", line, stats, "noise_margin_upstream_db")):
                continue
            elif (self._match("output power downstream: (-?\d+) db", line, stats, "output_power_downstream_db")):
                continue
            elif (self._match("attenuation upstream: (-?\d+) db", line, stats, "attenuation_upstream_db")):
                continue
            elif (re.match("tone.*", line)):
                stats['tones_upstream'] += self.parse_tones(line)

    def parse_chandata(self, stats, lines):
        for line in lines:
            m = re.search(".*DSL standard: (.*)", line)
            if m:
                stats['mode'] = m.group(1)
                continue
            elif (self._match("near-end interleaved channel bit rate: (\d+) kbps", line, stats, "bitrate_interleaved_downstream_kbps")):
                continue
            # TODO: clean up above match for this when in ADSL2 mode
            elif (self._match("near-end bit rate: (\d+) kbps", line, stats, "bitrate_interleaved_downstream_kbps")):
                continue
            elif (self._match("near-end fast channel bit rate: (\d+) kbps", line, stats, "bitrate_fast_downstream_kbps")):
                continue
            elif (self._match("far-end interleaved channel bit rate: (\d+) kbps", line, stats, "bitrate_interleaved_upstream_kbps")):
                continue
            # TODO: clean up above match for this when in ADSL2 mode
            elif (self._match("far-end bit rate: (\d+) kbps", line, stats, "bitrate_interleaved_upstream_kbps")):
                continue
            elif (self._match("far-end fast channel bit rate: (\d+) kbps", line, stats, "bitrate_fast_upstream_kbps")):
                continue

    def parse_perfdata(self, stats, lines):
        for line in lines:
            if self._match("near-end FEC error fast: (\d+)", line, stats, "error_fec_fast_downstream"):
                continue
            elif self._match("near-end FEC error interleaved: (\d+)", line, stats, "error_fec_interleaved_downstream"):
                continue
            elif self._match("near-end CRC error fast: (\d+)", line, stats, "error_crc_fast_downstream"):
                continue
            elif self._match("near-end CRC error interleaved: (\d+)", line, stats, "error_crc_interleaved_downstream"):
                continue
            elif self._match("near-end HEC error fast: (\d+)", line, stats, "error_hec_fast_downstream"):
                continue
            elif self._match("near-end HEC error interleaved: (\d+)", line, stats, "error_hec_interleaved_downstream"):
                continue
            elif self._match("far-end FEC error fast: (\d+)", line, stats, "error_fec_fast_upstream"):
                continue
            elif self._match("far-end FEC error interleaved: (\d+)", line, stats, "error_fec_interleaved_upstream"):
                continue
            elif self._match("far-end CRC error fast: (\d+)", line, stats, "error_crc_fast_upstream"):
                continue
            elif self._match("far-end CRC error interleaved: (\d+)", line, stats, "error_crc_interleaved_upstream"):
                continue
            elif self._match("far-end HEC error fast: (\d+)", line, stats, "error_hec_fast_upstream"):
                continue
            elif self._match("far-end HEC error interleaved: (\d+)", line, stats, "error_hec_interleaved_upstream"):
                continue
            else:
                m = re.search("ADSL uptime\s+(.*)", line)
                if (m):
                    stats['uptime'] = m.group(1)
                    continue

    def _parse_inet_line(self, line):
        m = re.search("inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}), netmask", line)
        if m:
            return m.group(1)
        return None

    def parse_ifconfig(self, stats, lines):
        line_len = len(lines)
        i = 0

        while i < line_len:
            line = lines[i]
            if re.match(".*enif0: mtu ", line):
                stats['lan_ip'] = self._parse_inet_line(lines[i+1])
            elif re.match(".*wanif0: mtu ", line):
                stats['wan_ip'] = self._parse_inet_line(lines[i+1])

            i += 1

    def parse(self, data):
        linedata_near_lines = []
        linedata_far_lines  = []
        chandata_lines      = []
        perfdata_lines      = []
        ifconfig_lines      = []
        current_buf = None

        lines = data.split("\n")
        line_number = 0

        for line in lines:
            line_number += 1

            line = line.strip()

            if line == "":
                continue

            # wan linedata near
            if line.startswith("noise margin downstream:"):
                current_buf = linedata_near_lines
            # wan linedata far
            elif line.startswith("noise margin upstream:"):
                current_buf = linedata_far_lines
            # wan chandata
            elif re.match(".*DSL standard: ", line):
                current_buf = chandata_lines
            # wan perfdata
            elif re.match(".*near-end FEC error fast:", line):
                current_buf = perfdata_lines
            # ip ifconfig
            elif re.match(".*enif0: mtu ", line):
                current_buf = ifconfig_lines

            if current_buf == None:
                continue

            current_buf += [line]

        stats = {}
        stats['time'] = int(time.time())
        stats['tones_downstream'] = []
        stats['tones_upstream'] = []

        self.parse_linedata_near(stats, linedata_near_lines)
        self.parse_linedata_far(stats, linedata_far_lines)
        self.parse_chandata(stats, chandata_lines)
        self.parse_perfdata(stats, perfdata_lines)
        self.parse_ifconfig(stats, ifconfig_lines)
        return stats

def load_from_stdin():
    parser = StatsParser()

    stats = parser.parse(stdin.read())

    print stats

if __name__ == '__main__':
    load_from_stdin()
