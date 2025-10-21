control 'container' do
  impact 0.5
  describe podman.containers do
    its('status') { should cmp /Up/ }
    its('commands') { should cmp /sleep/ }
    its('images') { should cmp /mysql-router:8.0/ }
    its('names') { should include "mysql-router-8.0" }
  end
end
control 'packages' do
  impact 0.5
  describe package('mysql-community-client') do
    it { should be_installed }
    its ('version') { should match '8.0.44.*' }
  end
  describe package('mysql-router-community') do
    it { should be_installed }
    its ('version') { should match '8.0.44.*' }
  end
end
