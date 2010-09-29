#!/usr/bin/env python

from sys import stdin
from helpers import time_since

import time

class DashboardBuilder:
    # data should be a dict
    def __init__(self, data):
        self.data = data

    def _get(self, key):
        try:
            return self.data[key]
        except:
            return None

    def _get_header(self):
        time_tuple = time.localtime(self._get('time'))
        time_str = time.strftime("%Y-%m-%d %H:%M %Z", time_tuple)
        f_time = time_since(self.data['time'])

        return """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <title>DSL Dashboard</title>
  <link rel="stylesheet" href="screen.css" media="screen" />
  <meta http-equiv="refresh" content="60"/>
</head>
<body>
<div id="content">
<h1>DSL Dashboard</h1>
<p style="color: #aaa; font-size: 90%%">%s (%s)</p>
<hr />
""" % (f_time, time_str)

    def _build_footer(self):
        return """
</div>
<p style="color: #aaa; font-size: 75%%; text-align: center;">Data Time: <span class="datum">%d</span></p>
</body>
</html>
""" % self.data['time']

    def _get_base_data(self):
        return """
<div id="base-data">
<p>Mode: <span class="datum">%s</span></p>
<p>Uptime: <span class="datum">%s</span></p>
</div>
""" % (self._get('mode'), self._get('uptime'))

    def _build_speed_stats(self):
        down_int = self._get('bitrate_interleaved_downstream_kbps') or 0
        down_fast = self._get('bitrate_fast_downstream_kbps') or 0
        up_int = self._get('bitrate_interleaved_upstream_kbps') or 0
        up_fast = self._get('bitrate_fast_upstream_kbps') or 0

        down = down_int + down_fast
        up = up_int + up_fast

        return """
<div id="speed-stats">
<p>Downstream Bit Rate: <span class="datum">%d kbps</span> (F: <span class="datum">%d</span>/I: <span class="datum">%d kbps</span>)</p>
<p>Upstream Bit Rate: <span class="datum">%d kbps</span> (F: <span class="datum">%d</span>/I: <span class="datum">%d kbps</span>)</p>
<p><a href="/munin/dreamfire.net/protego.dreamfire.net/zyxel_bitrate.html">history &raquo;</a></p>
</div>
""" % (down, down_fast, down_int, up, up_fast, up_int)

    def _build_line_stats(self):
        return """
<h2>Line Statistics</h2>
<table class="statistics">
<tr>
    <th></th>
    <th><a href="/munin/dreamfire.net/protego.dreamfire.net/zyxel_atten.html">Attenuation &raquo;</a></th>
    <th><a href="/munin/dreamfire.net/protego.dreamfire.net/zyxel_noise.html">Noise Margin &raquo;</a></th>
    <th><a href="/munin/dreamfire.net/protego.dreamfire.net/zyxel_power.html">Output Power &raquo;</a></th>
</tr>
<tr>
    <th>Downstream</th>
    <td><span class="datum">%d db</span></td>
    <td><span class="datum">%d db</span></td>
    <td><span class="datum">%d db</span></td>
</tr>
<tr>
    <th>Upstream</th>
    <td><span class="datum">%d db</span></td>
    <td><span class="datum">%d db</span></td>
    <td><span class="datum">%d db</span></td>
</tr>
</tr>
</table>
""" % (self._get('attenuation_downstream_db') or -1,
       self._get('noise_margin_downstream_db') or -1,
       self._get('output_power_downstream_db') or -1,
       self._get('attenuation_upstream_db') or -1,
       self._get('noise_margin_upstream_db') or -1,
       self._get('output_power_upstream_db') or -1)

    def _build_error_statsg(self):
        fec_i_down = self._get('error_fec_interleaved_downstream') or 0
        fec_f_down = self._get('error_fec_fast_downstream') or 0
        fec_down   = fec_i_down + fec_f_down

        fec_i_up   = self._get('error_fec_interleaved_upstream') or 0
        fec_f_up   = self._get('error_fec_fast_upstream') or 0
        fec_up     = fec_i_up + fec_f_up

        crc_i_down = self._get('error_crc_interleaved_downstream') or 0
        crc_f_down = self._get('error_crc_fast_downstream') or 0
        crc_down   = crc_i_down + crc_f_down

        crc_i_up   = self._get('error_crc_interleaved_upstream') or 0
        crc_f_up   = self._get('error_crc_fast_upstream') or 0
        crc_up     = crc_i_up + crc_f_up

        hec_i_down = self._get('error_hec_interleaved_downstream') or 0
        hec_f_down = self._get('error_hec_fast_downstream') or 0
        hec_down   = hec_i_down + hec_f_down

        hec_i_up   = self._get('error_hec_interleaved_upstream') or 0
        hec_f_up   = self._get('error_hec_fast_upstream') or 0
        hec_up     = hec_i_up + hec_f_up

        return """
<h2>Errors</h2>
<table class="statistics">
<tr>
    <th></th>
    <th>FEC</th>
    <th>CRC</th>
    <th>HEC</th>
</tr>
<tr>
    <th>Downstream</th>
    <td><span class="datum">%d</span> (F: <span class="datum">%d</span>/I: <span class="datum">%d</span>)</td>
    <td><span class="datum">%d</span> (F: <span class="datum">%d</span>/I: <span class="datum">%d</span>)</td>
    <td><span class="datum">%d</span> (F: <span class="datum">%d</span>/I: <span class="datum">%d</span>)</td>
</tr>
<tr>
    <th>Upstream</th>
    <td><span class="datum">%d</span> (F: <span class="datum">%d</span>/I: <span class="datum">%d</span>)</td>
    <td><span class="datum">%d</span> (F: <span class="datum">%d</span>/I: <span class="datum">%d</span>)</td>
    <td><span class="datum">%d</span> (F: <span class="datum">%d</span>/I: <span class="datum">%d</span>)</td>
</tr>
</table>
""" % (fec_down, fec_f_down, fec_i_down,
       crc_down, crc_f_down, crc_i_down,
       hec_down, hec_f_down, hec_i_down,
       fec_up, fec_f_up, fec_i_up,
       crc_up, crc_f_up, crc_i_up,
       hec_up, hec_f_up, hec_i_up)

    def _build_downstream_tonemap(self):
        return """
<h2>Downstream Tone Map</h2>
%s
""" % self._build_html_tonemap(self._get('tones_downstream'))

    def _build_upstream_tonemap(self):
        return """
<h2>Upstream Tone Map</h2>
%s
""" % self._build_html_tonemap(self._get('tones_upstream'))

    def _build_html_tonemap(self, tones):
        if tones == None:
            return "error"

        output = '<table class="tonemap">'

        height = 15
        while height >= 0:
            output += "<tr>"
            output += "<td>"
            if height % 5 == 0 and height != 0:
                output += '<span style="font-size:8pt">' + str(height) + '</span>'
            output += "&nbsp;</td>"

            for tone in tones:
                output += "<td"
                if tone > height:
                    output += ' class="fill"'
                output += '>&nbsp;</td>'

            output += "</tr>"
            height -= 1
        output += "</table>"

        output += """
<table class="tonemap-grid">
<tr>
<td class="first">%d</td>
<td>%d</td>
<td class="last">%d</td>
</table>
""" % (0, len(tones) / 2, len(tones))

        return output

    def _get_body(self):
        return \
               self._build_speed_stats() + \
               self._get_base_data() + \
               '<div class="clear"></div>' + \
               self._build_line_stats() + \
               self._build_error_statsg() + \
               self._build_downstream_tonemap() + \
               self._build_upstream_tonemap()

    def build(self):
        return self._get_header() + self._get_body() + self._build_footer()

def create_dashboard_from_stdin():
    data_dict = eval(stdin.read())
    dashboard = DashboardBuilder(data_dict)
    print dashboard.build()

if __name__ == "__main__":
    create_dashboard_from_stdin()
