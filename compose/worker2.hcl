disable_mlock = true

listener "tcp" {
	address = "worker2"
	purpose = "proxy"
	tls_disable = true
  // proxy_protocol_behavior = "allow_authorized"
	// proxy_protocol_authorized_addrs = "127.0.0.1:9200"
}

worker {
  name = "worker2"
  description = "A worker for a docker demo"
  address     = "worker2"
  public_addr = "localhost:9203"
  controllers = ["boundary"]
  tags {
    region    = ["us-west-1"],
    type      = ["dev", "database", "postgres"]
  }
}

kms "aead" {
  purpose = "worker-auth"
  aead_type = "aes-gcm"
  key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
  key_id = "global_worker-auth"
}