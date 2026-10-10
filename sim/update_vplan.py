#!/usr/bin/env python3
"""Generate the reviewable CSV/Markdown and native XLSX from actual regression data.

Uses Python's standard library; no spreadsheet service or third-party package.
Run from any directory: python3 sim/update_vplan.py
"""
import csv
import json
from collections import Counter
from pathlib import Path
from xml.etree.ElementTree import Element, SubElement, tostring
from zipfile import ZipFile, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
NS = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'


def column(index):
    result = ''
    while index:
        index, remainder = divmod(index-1, 26)
        result = chr(65+remainder) + result
    return result


def worksheet(rows, widths, header_row=1):
    root = Element('worksheet', xmlns=NS)
    views = SubElement(root, 'sheetViews')
    view = SubElement(views, 'sheetView', workbookViewId='0')
    SubElement(view, 'pane', ySplit=str(header_row), topLeftCell=f'A{header_row+1}', activePane='bottomLeft', state='frozen')
    columns = SubElement(root, 'cols')
    for i, width in enumerate(widths, 1):
        SubElement(columns, 'col', min=str(i), max=str(i), width=str(width), customWidth='1')
    data = SubElement(root, 'sheetData')
    for r, values in enumerate(rows, 1):
        row = SubElement(data, 'row', r=str(r), ht='64' if r>header_row else '26', customHeight='1')
        for c, value in enumerate(values, 1):
            style = '1' if r == header_row else {'PASS':'2','FAIL':'3','UNKNOWN':'4','OPEN':'3'}.get(str(value), '0')
            cell = SubElement(row, 'c', r=f'{column(c)}{r}', t='inlineStr', s=style)
            SubElement(SubElement(cell, 'is'), 't').text = str(value)
    SubElement(root, 'autoFilter', ref=f'A{header_row}:{column(max(map(len,rows)))}{len(rows)}')
    return tostring(root, encoding='utf-8', xml_declaration=True)


def workbook(path, sheets):
    types = Element('Types', xmlns='http://schemas.openxmlformats.org/package/2006/content-types')
    SubElement(types,'Default',Extension='rels',ContentType='application/vnd.openxmlformats-package.relationships+xml')
    SubElement(types,'Default',Extension='xml',ContentType='application/xml')
    SubElement(types,'Override',PartName='/xl/workbook.xml',ContentType='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml')
    SubElement(types,'Override',PartName='/xl/styles.xml',ContentType='application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml')
    wb = Element('workbook', xmlns=NS, attrib={'xmlns:r':'http://schemas.openxmlformats.org/officeDocument/2006/relationships'})
    ws = SubElement(wb,'sheets')
    rels = Element('Relationships', xmlns='http://schemas.openxmlformats.org/package/2006/relationships')
    for i, (name, rows, widths, header) in enumerate(sheets, 1):
        SubElement(types,'Override',PartName=f'/xl/worksheets/sheet{i}.xml',ContentType='application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml')
        SubElement(ws,'sheet',name=name,sheetId=str(i),attrib={'r:id':f'rId{i}'})
        SubElement(rels,'Relationship',Id=f'rId{i}',Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet',Target=f'worksheets/sheet{i}.xml')
    SubElement(rels,'Relationship',Id='styles',Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles',Target='styles.xml')
    styles = '''<?xml version="1.0" encoding="UTF-8"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="11"/><name val="Calibri"/></font></fonts>
<fills count="6"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF17365D"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFE2F0D9"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFFCE4D6"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFFFF2CC"/></patternFill></fill></fills>
<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="5"><xf fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf><xf fontId="1" fillId="2" borderId="0" xfId="0" applyFill="1" applyFont="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf><xf fontId="0" fillId="3" borderId="0" xfId="0" applyFill="1"/><xf fontId="0" fillId="4" borderId="0" xfId="0" applyFill="1"/><xf fontId="0" fillId="5" borderId="0" xfId="0" applyFill="1"/></cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>'''
    root_rels = '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'
    with ZipFile(path,'w',ZIP_DEFLATED) as archive:
        archive.writestr('[Content_Types].xml',tostring(types))
        archive.writestr('_rels/.rels',root_rels)
        archive.writestr('xl/workbook.xml',tostring(wb))
        archive.writestr('xl/_rels/workbook.xml.rels',tostring(rels))
        archive.writestr('xl/styles.xml',styles)
        for i, (_, rows, widths, header) in enumerate(sheets,1):
            archive.writestr(f'xl/worksheets/sheet{i}.xml',worksheet(rows,widths,header))


def main():
    plan = json.loads((ROOT/'docs/vplan.json').read_text())
    results = json.loads((ROOT/'docs/results/regress.json').read_text())
    bugs = json.loads((ROOT/'docs/bugs.json').read_text())
    coverage = json.loads((ROOT/'docs/results/coverage_metrics.json').read_text())
    if not results.get('complete') or len(results['runs']) != results['planned_count']:
        raise ValueError('VPlan requires a completed regression manifest')
    if {row['test'] for row in plan} != {row['test'] for row in results['runs']}:
        raise ValueError('VPlan test inventory does not match regression')
    header = ['Section','Main Title','Description','Testname','Priority','Method / Checker','Owner','Status','Milestone','Remark / Bug ID','Spec section','Seeds / Evidence']
    detail = []
    for item in plan:
        runs = [r for r in results['runs'] if r['test']==item['test']]
        state = 'FAIL' if any(r['status']=='FAIL' for r in runs) else ('PASS' if all(r['status']=='PASS' for r in runs) else 'UNKNOWN')
        evidence = '; '.join(f"seed={r['seed']} {r['status']} sim/{r['log']}" for r in runs)
        remark = item['bugs'] or ('Checker self-test; isolated pins, not a DUT compliance result' if item['id']=='SYS-04' else 'Executed with independent checks')
        detail.append([item['id'],item['group'],item['description'],item['test'],'P1',item['checker'],'DV',state,'2026-10-10',remark,item['spec'],evidence])
    counts = Counter(r[7] for r in detail)
    run_counts = Counter(r['status'] for r in results['runs'])
    plan_rows = [['Total Items',len(detail)],['Pass Items',counts['PASS']],['Fail Items',counts['FAIL']],['NY Items',counts['UNKNOWN']],['Signoff','NOT CLOSED: three confirmed RTL defects; W1C set-to-clear coverage blocked by UART-002'],[],header] + detail
    summary = [['Metric','Actual result'],['Date','2026-10-10'],['Branch','feat/uart-uvm-verification'],['Unique testcases',len(detail)],['DUT cases / checker self-test',f'{len(detail)-1} / 1'],['Regression runs',len(results['runs'])],['PASS / FAIL / UNKNOWN',f"{run_counts['PASS']} / {run_counts['FAIL']} / {run_counts['UNKNOWN']}"],['RTL integrity','9 files: SHA-256 identical to baseline 9ccfd39'],['RTL bug status','UART-001 OPEN; UART-002 OPEN; UART-003 OPEN'],['Merge policy','No merge; push feature branch only'],['Estimate','5 engineering days: requirements 0.5; VIP/env 1.5; tests 2; debug/report 1'],['Coverage scope','Observed exercise coverage; failing tests do not prove specification compliance']]
    for group in dict.fromkeys(row[1] for row in detail):
        group_counts = Counter(r[7] for r in detail if r[1]==group)
        summary.append([group,f"PASS={group_counts['PASS']} FAIL={group_counts['FAIL']} UNKNOWN={group_counts['UNKNOWN']}"])
    bug_header = ['Bug ID','State','Severity','Required behavior','Observed behavior','Reproduction','Localization / limit']
    bug_rows = [bug_header]+[[b[k] for k in ('id','state','severity','expected','actual','reproduce','localization')] for b in bugs]
    cov_rows = [['Coverage item','Measured result','Evidence / limitation']]+[[r['item'],r['value'],r['note']] for r in coverage]
    workbook(ROOT/'Vplan.xlsx', [('Summary',summary,[30,100],1),('Vplan',plan_rows,[14,28,72,40,10,80,10,14,18,64,24,95],7),('Bugs',bug_rows,[16,12,14,70,70,80,80],1),('Coverage',cov_rows,[35,25,100],1)])
    with (ROOT/'docs/Vplan.csv').open('w',newline='') as stream:
        writer=csv.writer(stream,lineterminator='\n');writer.writerow(header);writer.writerows(detail)
    lines=['# UART verification plan results','',f"{len(detail)} testcases; {len(results['runs'])} runs: {run_counts['PASS']} PASS, {run_counts['FAIL']} FAIL, {run_counts['UNKNOWN']} UNKNOWN.",'','All planned tests were executed. RTL compliance is not closed: parity and RX frame-timing defects remain open.','See `Vplan.xlsx` for checkers, references, seeds and bug details.','', '| ID | Group | Testcase | Status | Bug |','|---|---|---|---|---|']
    lines += [f'| {r[0]} | {r[1]} | `{r[3]}` | {r[7]} | {r[9] if r[7]=="FAIL" else "—"} |' for r in detail]
    (ROOT/'docs/VPLAN.md').write_text('\n'.join(lines)+'\n')
    print(f'Generated Vplan.xlsx: {len(detail)} testcase rows, 4 sheets')


if __name__ == '__main__':
    main()
