
from .base import Base
import re, os
import glob

docs = {}
PATH = __file__
PATH, _ = os.path.split(PATH)
for docpath in glob.glob(PATH + '/docs/*'):
    path, name = os.path.split(docpath)
    f = open(docpath)
    docs[name] = f.read()
    f.close()

builtin_vars = {
    'os':            'Get current OS of compiling-system',
    'host':          'Get current OS of localhost',
    'tmpdir':        'Temporary directory',
    'curdir':        'Current directory',
    'buildir':       'Build directory',
    'scriptdir':     'Script dictionary',
    'globaldir':     'Global-config directory',
    'configdir':     'Local-config directory',
    'programdir':    'Program directory',
    'projectdir':    'Project directory',
    'shell':         'Extern shell',
    'env':           'Get environment variable',
    'reg':           'Get windows register value'
}

class Source(Base):
    def __init__(self, vim):
        Base.__init__(self, vim)

        self.vim = vim
        self.name = 'xmake'
        self.mark = '[xmake]'
        self.filetypes = ['lua']
        self.input_pattern = r'\w+$|\$\($'

    def get_complete_position(self, context):
        input = context['input']
        word = re.search(r'\w+$', input)
        if word:
            return word.start()
        else:
            return len(input)

    def gather_candidates(self, context):
        global docs, builtin_vars

        if re.search('\$\(\w*$', context['input'][:context['complete_position']]):
            return [{'word': k, 'menu': builtin_vars[k]} for k in builtin_vars]
        else:
            return [{'word': k, 'info': docs.get(k)} for k in docs]
