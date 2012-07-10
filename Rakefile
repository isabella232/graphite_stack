### Imports & libraries
require 'rubygems'
require 'bundler'
Bundler.setup

require 'evoker/fullstack'
require 'evoker/python'
require 'rake/clean'
require 'tmpdir'
include Evoker

### Paths
ROOT = File.expand_path('root')
BUILD_PATH = File.expand_path('build')
CACHE_PATH = File.expand_path('cache')
DOWNLOAD_PATH = File.expand_path('download')

PIP = File.join(ROOT, 'bin/pip')
PIP_CACHE = File.expand_path(File.join(smart_const_get(:cache_path), 'pip'))
REQUIREMENTS_LOCK = File.join(ROOT, 'lib/python/requirements.txt.lock')
INSTALL_FILES = Dir['files/**/*[^~]'].select { |p| File.file?(p) }.sort
INSTALLED_FILE = File.join(ROOT, INSTALL_FILES.first.sub(/^files./, ''))

### Download URLs
VIRTUALENV_URL = 'https://raw.github.com/pypa/virtualenv/master/virtualenv.py'
PY2CAIRO_URL = 'http://cairographics.org/releases/py2cairo-1.10.0.tar.bz2'
GRAPHITE_URL_BASE = "https://launchpad.net/graphite/0.9/0.9.10/+download"
CARBON_URL = "#{GRAPHITE_URL_BASE}/carbon-0.9.10.tar.gz"
GRAPHITE_WEB_URL = "#{GRAPHITE_URL_BASE}/graphite-web-0.9.10.tar.gz"
WHISPER_URL = "#{GRAPHITE_URL_BASE}/whisper-0.9.10.tar.gz"

### Configuration
if RUBY_PLATFORM.downcase.include?('darwin')
  system('which llvm-gcc >/dev/null 2>&1')
  ENV['CC'] = 'llvm-gcc' if $?.exitstatus.zero?
  ENV['ARCHFLAGS'] = '-arch x86_64'
end

### Cleanup
CLEAN << DOWNLOAD_PATH
CLEAN << BUILD_PATH
CLOBBER << ROOT
CLOBBER << CACHE_PATH

### Helper functions
def installed(path)
  File.join(ROOT, path)
end

def pip_install(what)
  sh "#{PIP} install --download-cache=#{PIP_CACHE} --use-mirrors #{what}"
end

### Directories
mkdir_p ROOT unless Dir.exists?(ROOT)
mkdir_p PIP_CACHE unless Dir.exists?(PIP_CACHE)

Dir['pieces/*.rake'].each { |piece| load piece }

### High-level tasks
task :install_graphite => [ REQUIREMENTS_LOCK, :carbon, :graphite_web, :whisper ]
task :install => [ :install_graphite, INSTALLED_FILE  ]
task :default => [ :install ]

### Actual build
file PIP => download(VIRTUALENV_URL) do
  virtualenv_py = File.expand_path(dl('virtualenv.py'))
  chdir 'download' do
    # virtualenv leaves distribute tarball in current directory
    sh "#{smart_const_get(:python)} #{virtualenv_py} --distribute #{ROOT}"
  end
  rm_f File.join(ROOT, 'lib/python')
  ln_s File.basename(Dir[File.join(ROOT, 'lib/python*')].first), File.join(ROOT, 'lib/python')
end

file REQUIREMENTS_LOCK  => [ PIP, 'requirements.txt', :carbon ] do |t|
  sh "#{PIP} install --download-cache=cache/pip --use-mirrors -r requirements.txt"
  sh "#{PIP} freeze > #{t}"
end

from_tarball :py2cairo, PY2CAIRO_URL do
  file installed('lib/python/site-packages/cairo/__init__.py') => PIP do |t|
    chdir source_dir do
      touch .
      sh <<EOF
        export PYTHONPATH=#{ROOT} PATH=#{ROOT}/bin:$PATH \\
               LD_LIBRARY_PATH=#{ROOT}:#{ROOT}/lib:$LD_LIBRARY_PATH
        python ./waf clean
        python ./waf configure --libdir=#{ROOT}/lib
        python ./waf build
        python ./waf install
EOF
    end
    touch t.to_s
  end
end

from_tarball :carbon, CARBON_URL do
  file installed('bin/carbon-aggregator.py') => [ PIP ] do |t|
    touch source_dir
    rm_f source_file('setup.cfg')
    pip_install source_dir
    touch t.to_s
  end
end

from_tarball :graphite_web, GRAPHITE_WEB_URL do
  file installed('lib/python/site-packages/graphite/settings.py') => [ PIP ] do |t|
    touch source_dir
    rm_f source_file('setup.cfg')
    pip_install source_dir
    touch t.to_s
  end
end

from_tarball :whisper, WHISPER_URL do
  file installed('lib/python/site-packages/whisper.py') => [ PIP ] do |t|
    touch source_dir
    pip_install source_dir
    touch t.to_s
  end
end

file INSTALLED_FILE => [ :install_graphite ] + INSTALL_FILES do
  cp_r "files/.", "root"
  chmod 0755, Dir["root/service/**/*run"]
  chmod 0755, "root/service/graphite-web/manage"
  touch INSTALLED_FILE
end
