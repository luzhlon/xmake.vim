
from .base import Base

# Demo, this should be stored in files
docs = {
    'set_project': 'Set the project name',
    'target': 'define a target',
    'add_files': 'add some soure files'
}

class Source(Base):
    def __init__(self, vim):
        Base.__init__(self, vim)

        self.vim = vim
        self.name = 'xmake'
        self.mark = '[xmake]'
        self.filetypes = ['lua']

    def gather_candidates(self, context):
        global docs

        data = [{'word': k} for k in docs]
        for item in data:
            item['info'] = docs.get(item['word'])

        return data
