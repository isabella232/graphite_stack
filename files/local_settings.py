import sys
from os.path import realpath, dirname, join

GRAPHITE_ROOT = realpath(join(dirname(__file__), '..', '..', '..', '..'))
WEBAPP_DIR = join(GRAPHITE_ROOT, 'webapp')
CONF_DIR = join(GRAPHITE_ROOT, 'conf')
DATABASES = { 'default': {
    'ENGINE': 'django.db.backends.sqlite3',
    'NAME': join(GRAPHITE_ROOT, 'storage', 'graphite.db') }}

sys.path.append(CONF_DIR)
try:
    from custom_settings import *
except ImportError:
    pass
