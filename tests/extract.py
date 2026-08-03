import sys, xml.etree.ElementTree as ET
r = ET.parse(sys.argv[1]).getroot()
out = ["local M = {}"]
for m in r.find('Methods'):
    args = [a.get('Name') for a in m.find('Arguments')] if m.find('Arguments') is not None else []
    out.append("function M:%s(%s)%send" % (m.get('Name'), ", ".join(args), m.find('Code').text))
out.append("return M")
open(sys.argv[2], 'w').write("\n".join(out))
