require "serverspec"
require "docker"

describe "Dockerfile" do
  before(:all) do
    image = Docker::Image.build_from_dir('.')

    set :os, family: :debian
    set :backend, :docker
    set :docker_image, image.id
  end

  %w{git wget curl default-jdk nodejs haproxy supervisor}.each do |p|
    it "installs package #{p}" do
      expect(package(p)).to be_installed
    end
  end

  describe command('mvn -v') do
    its(:stdout) { should match /Apache Maven 3\.3\.3/ }
  end

  describe file('/etc/apt/sources.list.d/nodesource.list') do
    it { should be_file }
  end

  describe file('/usr/src/couchdb') do
    it { should be_directory }
  end

  describe file('/usr/src/couchdb/dev/run') do
    it { should be_file }
  end

  describe file('/usr/src/clouseau') do
    it { should be_directory }
  end

  describe file('/usr/src/clouseau/target') do
    it { should be_directory }
  end

  describe file('/etc/supervisor/conf.d/supervisord.conf') do
    it { should be_file }
  end

  describe file('/var/log/supervisor/') do
    it { should be_directory }
  end
end
