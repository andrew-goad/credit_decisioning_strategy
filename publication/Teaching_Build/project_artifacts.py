"""Assemble the artifact view from the reviewed documents and the pinned SQL checkout."""
import base64
from pathlib import Path
from lxml import html
from urllib.parse import quote

WORK = Path(__file__).resolve().parent


def build_artifacts(repo, commit):
    module1 = next(repo.glob('Module_1*/v2.0'))
    module2 = next(repo.glob('Module_2*/v1.0'))
    def link(path, mode='blob'):
        if mode == 'raw':
            return f'https://raw.githubusercontent.com/andrew-goad/credit_decisioning_strategy/{commit}/{quote(path.relative_to(repo).as_posix())}'
        return f'https://github.com/andrew-goad/credit_decisioning_strategy/{mode}/{commit}/{quote(path.relative_to(repo).as_posix())}'

    def embedded(path, mime):
        return 'data:' + mime + ';base64,' + base64.b64encode(path.read_bytes()).decode('ascii')

    def component(name):
        return (WORK / name).read_text(encoding='utf-8')

    def parameter_panel(filename):
        element = html.fromstring(component(filename))
        heading = element.xpath('./h2 | ./h3')[0]
        heading.tag = 'summary'
        element.tag = 'details'
        element.set('class', 'parameter-module')
        for table in element.xpath('.//table'):
            parent = table.getparent()
            if 'parameter-table' not in parent.get('class', '').split():
                wrapper = html.Element('div', {'class': 'parameter-table'})
                parent.replace(table, wrapper)
                wrapper.append(table)
                parent = wrapper
            caption = table.find('caption')
            if caption is not None:
                parent.set('role', 'region')
                parent.set('aria-label', caption.text_content())
                parent.set('tabindex', '0')
        return html.tostring(element, encoding='unicode', method='html')

    brd = next((module1 / 'docs').glob('*BRD*.pdf'))
    explorer = module1 / 'tests/module1_v1_v2_release_impact_explorer.png'
    workbook = module1 / 'tests/Module1_V1_V2_Release_Validation.pbix'
    page = component('artifacts.html')
    values = {
        'ONE_SQL': link(next((module1 / 'src').glob('*.sql'))),
        'TWO_SQL': link(next((module2 / 'src').glob('*.sql'))),
        'ONE_RAW': link(next((module1 / 'src').glob('*.sql')), 'raw'),
        'TWO_RAW': link(next((module2 / 'src').glob('*.sql')), 'raw'),
        'ONE_BRD': link(brd),
        'ONE_VALID': link(next((module1 / 'tests').glob('*Validation_Summary*.pdf'))),
        'TWO_BRD_PDF': embedded(module2 / 'docs/MODULE_2_BUSINESS_REQUIREMENTS.pdf', 'application/pdf'),
        'TWO_VALID_PDF': embedded(module2 / 'tests/MODULE_2_VALIDATION_SUMMARY.pdf', 'application/pdf'),
        'FLOW_CONTENT': component('code-flows.html'),
        'M1_FLOW_SOURCE': link(brd) + '#page=9',
        'M2_ORIGINAL': link(next((module2 / 'docs').glob('*Architecture.png'))),
        'OPERATING_CONTENT': component('setting-parameters.html'),
        'M1_REF': parameter_panel('m1-parameter-reference.html'),
        'M2_REF': parameter_panel('m2-parameter-reference.html'),
        'PBIX_RAW': link(workbook, 'raw'),
        'PBIX_FILE': link(workbook),
        'EXPLORER_FULL': link(explorer),
        'EXPLORER_THUMB': embedded(explorer, 'image/png'),
        'EXECUTIVE_FULL': link(module1 / 'tests/module1_v1_v2_release_validation_executive_summary.png'),
        'EXPLORER_ORIG': link(explorer),
    }
    for key, value in values.items():
        marker = '@@' + key + '@@'
        if marker not in page:
            raise ValueError(f'Missing artifact component {marker}')
        page = page.replace(marker, value)
    return page
