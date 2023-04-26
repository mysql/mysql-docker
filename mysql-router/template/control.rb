control 'container' do
  impact 0.5
  describe podman.containers do
    its('status') { should cmp /Up/ }
    its('commands') { should cmp /sleep/ }
    its('images') { should cmp /mysql-router:%%MAJOR_VERSION%%/ }
    its('names') { should include "mysql-router-%%MAJOR_VERSION%%" }
  end
end
control 'packages' do
  impact 0.5
  describe package('%%MYSQL_CLIENT_PACKAGE_NAME%%') do
    it { should be_installed }
    its ('version') { should match '%%MYSQL_CLIENT_VERSION%%.*' }
  end
  describe package('%%MYSQL_ROUTER_PACKAGE_NAME%%') do
    it { should be_installed }
    its ('version') { should match '%%MYSQL_ROUTER_VERSION%%.*' }
  end
end
