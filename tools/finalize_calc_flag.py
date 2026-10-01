"""
Final step after LibreOffice recalculation: LibreOffice drops the 'recalculate on open' flag when it saves.
This rewrites only xl/workbook.xml <calcPr> to request a full recalculation on open
(fullCalcOnLoad="1", calcMode="auto", forceFullCalc="1"); every other part of the file, including the
cached values, is copied byte for byte.
Usage: python3 finalize_calc_flag.py <workbook.xlsx>
"""
import re, shutil, sys, zipfile

path = sys.argv[1]; tmp = path + ".tmp"
with zipfile.ZipFile(path) as zin, zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
    for item in zin.infolist():
        data = zin.read(item.filename)
        if item.filename == "xl/workbook.xml":
            xml = data.decode("utf-8")
            new = '<calcPr calcId="191029" calcMode="auto" fullCalcOnLoad="1" forceFullCalc="1" iterate="false" refMode="A1"/>'
            if re.search(r"<calcPr[^>]*/>", xml):
                xml = re.sub(r"<calcPr[^>]*/>", new, xml)
            else:
                xml = xml.replace("</workbook>", new + "</workbook>")
            data = xml.encode("utf-8")
        zout.writestr(item, data)
shutil.move(tmp, path)
with zipfile.ZipFile(path) as z:
    print(re.search(r"<calcPr[^>]*>", z.read("xl/workbook.xml").decode()).group(0))
