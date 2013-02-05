require 'rubygems'
require 'bundler'
Bundler.setup

require 'pathname'
require 'fpm'
require 'rake/clean'

SRC_PKG = FPM::Package::Dir.new
SRC_PKG.name        = 'graphite-stack'
SRC_PKG.version     = '0.9.10'
SRC_PKG.iteration   = '3oc1'
SRC_PKG.description = 'Full Graphite stack'
SRC_PKG.url         = 'https://github.com/3ofcoins/graphite-stack'
SRC_PKG.maintainer  = 'Maciej Pasternacki <maciej@pasternacki.net>'
SRC_PKG.provides    = %w|graphite graphite-web whisper carbon|

PREFIX    = Pathname.new('/opt/graphite')
DESTDIR   = Pathname.new('root').expand_path
VENDOR    = Pathname.new('vendor').expand_path
BUILD     = Pathname.new('build')
DESTROOT  = DESTDIR  + PREFIX.relative_path_from(Pathname.new('/'))
PIP       = DESTROOT + 'bin/pip'
PACKAGES  = DESTROOT + 'doc/packages.txt'

DEB_PKG = SRC_PKG.convert(FPM::Package::Deb)
SRC_PKG.attributes[:chdir]     = DESTDIR.to_s
DEB_PKG.attributes[:deb_user]  = 'root'
DEB_PKG.attributes[:deb_group] = 'root'

if RUBY_PLATFORM.downcase.include?('darwin')
  system('which llvm-gcc >/dev/null 2>&1')
  ENV['CC'] = 'llvm-gcc' if $?.exitstatus.zero?
  ENV['ARCHFLAGS'] = '-arch x86_64'
end

CLEAN << DESTDIR
CLEAN << BUILD
CLEAN << DEB_PKG.to_s

class Pathname
  def [](*globs)
    globs.inject([]) do |acc, glob|
      acc + self.class.glob(self + glob)
    end
  end
end

file PIP do
  python     = ENV['PYTHON'] || 'python'
  virtualenv = "#{python} vendor/virtualenv/virtualenv.py"
  sh "#{virtualenv} --distribute --verbose --never-download #{DESTROOT}"
  ln_sf DESTROOT['lib/python?*'].first.basename,
        DESTROOT.join('lib/python')
end

desc "Prepare install/build environment"
task :prepare => PIP

file PACKAGES => PIP do
  mkdir_p BUILD
  cp_r VENDOR['carbon', 'graphite-web', 'whisper', 'py2cairo'],
       BUILD, :remove_destination => true

  cmd = "#{PIP} install"
  if ENV['UNFROZEN']
    cmd << " -r requirements.txt"
  else
    cmd <<
      " --no-index -f file://#{VENDOR+'pip'} -r #{VENDOR+'requirements.txt'}"
  end

  sh "#{cmd} #{BUILD.join('carbon')} #{BUILD.join('graphite-web')} #{BUILD.join('whisper')}"

  chdir BUILD + 'py2cairo' do
    sh <<-EOF
      . #{DESTROOT}/bin/activate ;
      python ./waf configure --prefix=#{PREFIX} &&
      python ./waf build &&
      python ./waf install --destdir=#{DESTDIR}
    EOF
  end

  mkdir_p PACKAGES.dirname
  sh "#{PIP} freeze > #{PACKAGES}"
end

desc "Install Graphite with dependencies to local root"
task :install_software => PACKAGES

desc "Install supporting files to local root"
task :install_files => PIP do
  cp_r "files/.", DESTROOT
  chmod 0755, DESTROOT['service/**/*run', 'service/graphite-web/manage']
end

desc "Postprocess installed software for packaging"
task :postprocess => :install_software do
  chdir DESTROOT + 'bin' do
    sh   "sed -i~path s,#{DESTDIR},/, *"
    rm_f Dir["*~path"]
  end
end

desc "Install all to local root"
task :install => [:install_software, :install_files]

desc "Package file"
file DEB_PKG.to_s => [:install, :postprocess] do
  SRC_PKG.input '.'
  DEB_PKG.output(DEB_PKG.to_s)
end

desc "Build the package"
task :package => DEB_PKG.to_s

task :default => :package

task :pry do
  require 'pry'
  binding.pry
end

# Updating precise requirement list
task :unfreeze do
  ENV['UNFROZEN'] = '1'
end

desc "Freeze currently vendored pip requirements"
task :freeze do
  sh 'git rm vendor/requirements.txt vendor/pip/*'
  Rake::Task[:install_software].invoke
  File.open 'vendor/requirements.txt', 'w' do |f|
    f.write `#{PIP} freeze`.
      lines.
      grep(/^(?!(?:carbon|whisper|graphite-web)==)/).
      join
  end
  mkdir_p VENDOR+'pip'
  sh "#{PIP} install -r vendor/requirements.txt --download vendor/pip"
  sh 'git add vendor/requirements.txt vendor/pip/*'
  puts <<EOF
***
*** All changes are staged in git. Review and commit or revert.
***
EOF
end

desc "Install software from pip and update vendored cache"
task :refreeze => [ :clean, :unfreeze, :install_software, :freeze ]
