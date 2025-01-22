control 'container' do
  impact 0.5
  describe podman.containers do
    its('status') { should cmp /Up/ }
    its('commands') { should cmp /mysqld/ }
    its('images') { should cmp /mysql-cluster:8.4/ }
    its('names') { should include "mysql-cluster-8.4" }
  end
end
control 'packages' do
  impact 0.5
  describe package('mysql-cluster-community-server-minimal') do
    it { should be_installed }
    its ('version') { should match '8.4.4.*' }
  end
  describe package('mysql-shell') do
    it { should be_installed }
    its ('version') { should match '8.4.4.*' }
  end
end
