import glob

#from distutils.core import setup
#from distutils.extension import Extension
from setuptools import Extension, setup

from Cython.Distutils import build_ext

ext_modules = [Extension('gevent_couchbase.core.couchbase',
                         ['gevent_couchbase/core/couchbase.pyx'],
                         include_dirs=['/usr/local/include'],
                         runtime_library_dirs=['/usr/local/lib'],
                         libraries=['couchbase', 'ev', 'couchbase_libev'],
                         extra_compile_args=[],
                         extra_link_args=[],
                         )]

setup(
    name = 'gevent-couchbase',
    cmdclass = {'build_ext': build_ext},
    ext_modules = ext_modules,
    packages = ['gevent_couchbase',
                'gevent_couchbase.core']
)
