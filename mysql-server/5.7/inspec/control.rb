control 'container' do
  impact 0.5
  describe podman.containers do
    its('status') { should cmp /Up/ }
    its('commands') { should cmp /mysqld/ }
    its('images') { should cmp /mysql-server:5.7/ }
    its('names') { should include "mysql-server-5.7" }
  end
end
control 'packages' do
  impact 0.5
  describe package('mysql-community-server-minimal') do
    it { should be_installed }
    its ('version') { should match '5.7.44.*' }
  end
  describe package('mysql-shell') do
    it { should be_installed }
    its ('version') { should match '8.0.35.*' }
  end
end
