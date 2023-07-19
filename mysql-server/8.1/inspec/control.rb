control 'container' do
  impact 0.5
  describe podman.containers do
    its('status') { should cmp /Up/ }
    its('commands') { should cmp /mysqld/ }
    its('images') { should cmp /mysql-server:8.1/ }
    its('names') { should include "mysql-server-8.1" }
  end
end
control 'packages' do
  impact 0.5
  describe package('mysql-community-server-minimal') do
    it { should be_installed }
    its ('version') { should match '8.1.0.*' }
  end
  describe package('mysql-shell') do
    it { should be_installed }
    its ('version') { should match '8.1.0.*' }
  end
end
