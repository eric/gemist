module Gemist
  @@gems = Hash.new { |h,role| h[role] = {} }

  # Usage:
  #   role(:app, %w(hpricot mongrel))
  # or
  #   role(:app, 'god', :version => '>= 0.7.7')
  def role(role, *gems)
    options = { :version => '>= 0' }

    if gems.last.is_a?(Hash)
      options.merge!(gems.pop)
    end

    gems.flatten.each do |gem|
      @@gems[role][gem] = options
    end

    namespace :gems do
      unless @_gemist_tasks_defined
        desc "Install all required gems"
        task :install do
          @@gems.keys.each do |role|
            send(role).send(:install)
          end
        end
        @_gemist_tasks_defined = true
      end

      namespace role do
        desc "Install required gems"
        task :install, :roles => role do
          @@gems[role].each do |gem,version|
            gemist.install_gem(gem, version)
          end
        end
      end
    end
  end

  def install_system
    url = "http://rubyforge.org/frs/download.php/38646/rubygems-1.2.0.tgz"
    filename = 'rubygems-1.2.0.tgz'
    expanded_directory = 'rubygems-1.2.0'

    run "mkdir -p #{shared_path}/opt/src #{shared_path}/opt/dist #{shared_path}/opt/bin"
    run "curl -L -q -o #{shared_path}/opt/dist/#{filename} #{url}"
    run "rm -rf #{shared_path}/opt/src/#{expanded_directory}"
    run "tar zxvf #{shared_path}/opt/dist/#{filename} -C #{shared_path}/opt/src"
    run "cd #{shared_path}/opt/src/#{expanded_directory} && sudo ruby setup.rb"
  end

  # Upgrade the *gem* system to the latest version. Runs via *sudo*
  def update_system
    gem_install = fetch('gemist_gem_install') { "gem install --no-rdoc --no-ri" }
    gem_update = fetch('gemist_gem_update') { gem_install.sub('install', 'update') }

    send(run_method, "#{gem_update} --system")
  end

  # Auto selects a gem from a list and installs it.
  #
  # *gem* has no mechanism on the command line of disambiguating builds for
  # different platforms, and instead asks the user. This method has the necessary
  # conversation to select the +version+ relevant to +platform+ (or the one nearest
  # the top of the list if you don't specify +version+).
  def install_gem(package, options = {})
    version = options.delete(:version) || '>= 0.0.0'
    platform = options.delete(:platform) || 'ruby'
    source = options.delete(:source)

    gem_install = fetch('gemist_gem_install') { "gem install --no-rdoc --no-ri" }

    source_arg = "--source #{source}" if source
    version_arg = "--version '#{version}'"

    selections={}
    gem_installed = %(ruby -rubygems -e 'exit(Gem.source_index.find_name(%(#{package}), %(#{version})).size > 0)')
    cmd = %(/bin/sh -c "#{gem_installed} || #{gem_install} #{source_arg} #{version_arg} #{package}")
    send run_method, cmd, :shell => false, :pty => true do |channel, stream, data|
      data.each_line do |line|
        case line
        when /\s(\d+).*\(#{platform}\)/
          unless selections[channel[:host]]
            selections[channel[:host]]=$1.dup+"\n"
            logger.info "Selecting #$&", "#{stream} :: #{channel[:host]}"
          end
        when /\s\d+\./
          # Discard other selections from data stream
        when /^>/
          channel.send_data selections[channel[:host]]
          logger.debug line, "#{stream} :: #{channel[:host]}"
        else
          logger.info line, "#{stream} :: #{channel[:host]}"
        end
      end
    end
  end
end

Capistrano.plugin :gemist, Gemist

Capistrano::Configuration.instance(:must_exist).load do
  namespace :gems do
    desc "Install rubygems"
    task :install_system do
      gemist.install_system
    end
     desc "Update rubygems"
    task :update_system do
      gemist.update_system
    end
  end
end
