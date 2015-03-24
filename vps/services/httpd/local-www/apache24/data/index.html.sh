#!/bin/sh
cat <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>${HOSTNAME}</title>
  <style type="text/css">
    body { background-color: #eee; }
    .content { 
      background-color: #fff; 
      border: 1px solid black; 
      width: 600px; 
      position: relative; 
      top: 100px; 
      margin-left: auto;
      margin-right: auto;
    }
    .content p {
      margin: 4px;
      padding: 4px;
      font: normal 10pt/14px Verdana, Arial, Helvetica;
    }
    h1 { font-size: 110%; font-weight: bold; margin: 4px; text-align: center; }
    h2 { font-size: 100%; font-weight: normal; margin: 4px; text-align: center; }
  </style>
</head>
<body>
  <div class="content">
    <h1>${HOSTNAME}</h1>
    <h2>The Dreamfire Solutions Group</h2>
    <hr/>
    <p>
      Welcome to <strong>${HOSTNAME}</strong>.
    </p>
    <p>
      This server is owned and operated by
      The Dreamfire Solutions Group. Inquiries may be addressed to
      <tt>sr<!-- -->ees&laquo;@&raquo;dr<!-- -->eamfi<!-- -->resolu<!-- -->tions.com</tt>.
    </p>
    <p>
      <strong>Notice:</strong> Access to this server is restricted to
      authorized persons only.
    </p>
    <div style="position: relative; width: 171px; margin-left: auto; margin-right: auto">
      <img src="freebsd_pb.gif" alt="Powered by FreeBSD" width="171" hieght="64"/>
    </div>
  </div>
</body>
</html>
