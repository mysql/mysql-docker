control 'container' do
  impact 0.5
  describe podman.containers do
    its('status') { should cmp /Up/ }
    its('commands') { should cmp /mysqld/ }
    its('images') { should cmp /mysql-cluster:%%MAJOR_VERSION%%/ }
    its('names') { should include "mysql-cluster-%%MAJOR_VERSION%%" }
  end
end
control 'packages' do
  impact 0.5
  describe package('%%MYSQL_SERVER_PACKAGE_NAME%%') do
    it { should be_installed }
    its ('version') { should match '%%MYSQL_VERSION%%.*' }
  end
  describe package('%%MYSQL_SHELL_PACKAGE_NAME%%') do
    it { should be_installed }
    its ('version') { should match '%%MYSQL_SHELL_VERSION%%.*' }
  end
  describe command("rpm -qa --qf '%{NAME}\\n' 'mysql*-release*'") do
    its('stdout') { should eq '' }
    its('exit_status') { should eq 0 }
  end
  describe command("find /etc/yum.repos.d -maxdepth 1 -type f -name 'mysql*.repo' -print -quit") do
    its('stdout') { should eq '' }
    its('exit_status') { should eq 0 }
  end
end
