describe http('http://localhost:9200', open_timeout: 60, read_timeout: 60, ssl_verify: false, max_redirects: 3) do
  its('status') { should eq 200 }
end
