// compose/worker2.hcl

disable_mlock = true

listener "tcp" {
	address = "worker2"
	purpose = "proxy"
	tls_disable = true
}

worker {
  name = "worker2"
  description = "A worker for a docker demo"
  address     = "worker2"
  public_addr = "localhost:9203"
  controllers = ["boundary"]
  tags {
    region    = ["us-west-1"],
    type      = ["dev"]
    // type      = ["dev", "database", "redis"]
  }
}

kms "aead" {
  purpose = "worker-auth"
  aead_type = "aes-gcm"
  key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
  key_id = "global_worker-auth"
}