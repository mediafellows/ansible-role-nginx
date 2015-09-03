require 'spec_helper'

describe "Nginx setup" do
  describe package('nginx') do
    it { should be_installed }
    if ANSIBLE_VARS.fetch('nginx_official_repo', false)
      its(:version) { should > '1.8.0' }
    end
  end

  describe service('nginx') do
    it { should be_enabled }
    it { should be_running }
  end

  describe file('/etc/nginx/nginx.conf') do
    it { should be_file }
    it { should contain ANSIBLE_VARS.fetch('nginx_http_params', 'FAIL').join(";\n") }
  end

  describe file('/etc/nginx/sites-available/') do
    it { should be_directory }
  end

  describe file('/etc/nginx/sites-enabled/') do
    it { should be_directory }
  end

  describe file('/etc/nginx/sites-enabled/default') do
    it { should_not exist }
  end

  describe file('/etc/nginx/conf.d/default.conf') do
    it { should_not exist }
  end

  ANSIBLE_VARS.fetch('nginx_sites', nil).each do |name, config|
    describe file("/etc/nginx/sites-available/#{name}.conf") do
      it { should be_file }
      it { should contain "#{config.join(";\n")}" }
    end
  end

  ANSIBLE_VARS.fetch('nginx_sites', nil).each do |name, config|
    describe file("/etc/nginx/sites-enabled/#{name}.conf") do
      it { should be_symlink }
    end
  end

  describe file("#{ANSIBLE_VARS.fetch('nginx_log_dir', 'FAIL')}/") do
    it { should be_directory }
    it { should be_owned_by('www-data') }
  end

  # NOT really dynamic (hardcoded filename) if params change!
  describe file('/var/log/nginx/access.log') do
    it { should be_file }
  end

  describe file('/var/log/nginx/error.log') do
    it { should be_file }
  end
end
