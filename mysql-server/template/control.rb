control 'container' do
  impact 0.5
  describe podman.containers do
    its('status') { should cmp /Up/ }
    its('commands') { should cmp /mysqld/ }
    its('images') { should cmp /%%CONT_NAME%%:%%MAJOR_VERSION%%/ }
    its('names') { should include "%%CONT_NAME%%-%%MAJOR_VERSION%%" }
  end
end
control 'packages' do
  impact 0.5
  describe package('%%MYSQL_SERVER_PACKAGE_NAME%%') do
    it { should be_installed }
    its ('version') { should match '%%MYSQL_SERVER_VERSION%%.*' }
  end
  describe package('%%MYSQL_SHELL_PACKAGE_NAME%%') do
    it { should be_installed }
    its ('version') { should match '%%MYSQL_SHELL_VERSION%%.*' }
  end
end
