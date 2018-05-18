require 'spec_helper'

describe "Nginx setup" do
  describe ppa('nginx/stable') do
    it { should exist }
    it { should be_enabled }
  end

  describe package('nginx') do
    it { should be_installed }
    its(:version) { should > '1.8.0' }
  end

  describe service('nginx') do
    it { should be_enabled }
    it { should be_running }
  end

  nginx_conf_dir = ANSIBLE_VARS.fetch('nginx_conf_dir', '/etc/nginx')

  describe file("#{nginx_conf_dir}/nginx.conf") do
    it { should be_file }
    config_string = ANSIBLE_VARS.fetch('nginx_http_params', 'FAIL').join(";\n  ")
    config_string.gsub!(/{{(.+)}}/){ ANSIBLE_VARS.fetch($1, 'NOT FOUND') }
    its(:content) { should include("  #{config_string}") }
  end

  describe file("#{nginx_conf_dir}/sites-available/") do
    it { should be_directory }
    it { should be_owned_by('root') }
    it { should be_grouped_into('www-data') }
  end

  describe file("#{nginx_conf_dir}/sites-enabled/") do
    it { should be_directory }
    it { should be_owned_by('root') }
    it { should be_grouped_into('www-data') }
  end

  describe file("#{nginx_conf_dir}/auth_basic/") do
    it { should be_directory }
    it { should be_owned_by('root') }
    it { should be_grouped_into('www-data') }
  end

  describe file("#{nginx_conf_dir}/conf.d/") do
    it { should be_directory }
    it { should be_owned_by('root') }
    it { should be_grouped_into('www-data') }
  end

  describe file("#{nginx_conf_dir}/sites-enabled/default") do
    it { should_not exist }
  end

  describe file("#{nginx_conf_dir}/conf.d/default.conf") do
    it { should_not exist }
  end

  ANSIBLE_VARS.fetch('nginx_sites', nil).each do |site|
    describe file("#{nginx_conf_dir}/sites-available/#{site['name']}.conf") do
      it { should be_file }
      server_config = site['server'].join("-").gsub(/{{(.+)}}/){ ANSIBLE_VARS.fetch($1, 'NOT FOUND') }
      server_config_string = "server {\n  #{server_config.gsub(";", ";\n    ").gsub("-", ";\n  ").gsub("{", "{\n    ").gsub("};", "}").gsub("    }", "    \n   }")}\n}"
      its(:content) { should match(server_config_string) }
      its(:content) { should include("upstream #{site['upstream'].first.first} {") } if site['upstream']
    end
  end

  ANSIBLE_VARS.fetch('nginx_sites', nil).each do |site|
    describe file("#{nginx_conf_dir}/sites-available/#{site['name']}.conf") do
      if site['upstream_group']
        its(:content) { should include("upstream #{site['upstream_group']['name']} {") }

        server_config = site['upstream_group']['base_string'].gsub(/{{(.+)}}/){ ANSIBLE_VARS.fetch($1, 'NOT FOUND') }
        its(:content) { should include(server_config.gsub('$#', '0')) }
      end
    end
  end

  ANSIBLE_VARS.fetch('nginx_sites', nil).each do |site|
    describe file("#{nginx_conf_dir}/sites-enabled/#{site['name']}.conf") do
      it { should be_symlink }
    end
  end

  describe file("#{ANSIBLE_VARS.fetch('nginx_log_dir', 'FAIL')}/") do
    it { should be_directory }
    it { should be_owned_by('www-data') }
  end

  if ANSIBLE_VARS.fetch('nginx_cors', false)
    describe file("#{nginx_conf_dir}/nginx-cors.conf") do
      it { should be_file }
    end
  end

  if ANSIBLE_VARS.fetch('nginx_os_tuning', true)
    describe file('/etc/security/limits.conf') do
      its(:content) { should include('www-data    hard    nofile    30000') }
      its(:content) { should include('www-data    soft    nofile    30000') }
    end

    describe file('/etc/sysctl.conf') do
      its(:content) { should include('net.core.netdev_max_backlog = 2048') }
      its(:content) { should include('net.core.somaxconn = 2048') }
    end
  end

  # NOT really dynamic (hardcoded filename) if params change!
  describe file('/var/log/nginx/access.log') do
    it { should be_file }
  end

  describe file('/var/log/nginx/error.log') do
    it { should be_file }
  end
end
