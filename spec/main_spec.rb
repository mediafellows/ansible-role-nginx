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
  end
end
