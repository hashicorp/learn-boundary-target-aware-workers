disable_mlock = true

listener "tcp" {
	address = "worker2:9203"
	purpose = "proxy"
	tls_disable = true
}

worker {
  name = "worker2"
  description = "A worker for a docker demo"
  address     = "worker2"
  public_addr = "localhost"
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