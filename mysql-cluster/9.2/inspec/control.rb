control 'container' do
  impact 0.5
  describe podman.containers do
    its('status') { should cmp /Up/ }
    its('commands') { should cmp /mysqld/ }
    its('images') { should cmp /mysql-cluster:9.2/ }
    its('names') { should include "mysql-cluster-9.2" }
  end
end
control 'packages' do
  impact 0.5
  describe package('mysql-cluster-community-server-minimal') do
    it { should be_installed }
    its ('version') { should match '9.2.0.*' }
  end
  describe package('mysql-shell') do
    it { should be_installed }
    its ('version') { should match '9.2.0.*' }
  end
end
