control 'container' do
  impact 0.5
  describe podman.containers do
    its('status') { should cmp /Up/ }
    its('commands') { should cmp /mysqld/ }
    its('images') { should cmp /mysql-cluster:9.7/ }
    its('names') { should include "mysql-cluster-9.7" }
  end
end
control 'packages' do
  impact 0.5
  describe package('mysql-cluster-community-server-minimal') do
    it { should be_installed }
    its ('version') { should match '9.7.3.*' }
  end
  describe package('mysql-shell') do
    it { should be_installed }
    its ('version') { should match '26.7.1.*' }
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
