control 'container' do
  impact 0.5
  describe podman.containers do
    its('status') { should cmp /Up/ }
    its('commands') { should cmp /mysqld/ }
    its('images') { should cmp /mysql-server:mysql-community-minimal-release/ }
    its('names') { should include "mysql-server-mysql-community-minimal-release" }
  end
end
control 'packages' do
  impact 0.5
  describe package('mysql-community-server-minimal') do
    it { should be_installed }
    its ('version') { should match 'mysql-community-minimal-release.*' }
  end
  describe package('mysql-shell') do
    it { should be_installed }
    its ('version') { should match 'mysql80-community-release.*' }
  end
end
