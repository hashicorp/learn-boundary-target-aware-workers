disable_mlock = true

worker {
  name = "docker-worker-1"
  description = "A worker for a docker demo"
  // address = "worker"
  address = "worker1"
  controllers = ["boundary"]
}

listener "tcp" {
  // address = "worker"
	address = "worker1:9202"
	purpose = "proxy"
	tls_disable = true
  //       proxy_protocol_behavior = "allow_authorized"
	// proxy_protocol_authorized_addrs = "127.0.0.1"
}

kms "aead" {
  purpose = "worker-auth"
  aead_type = "aes-gcm"
  key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
  key_id = "global_worker-auth"
}