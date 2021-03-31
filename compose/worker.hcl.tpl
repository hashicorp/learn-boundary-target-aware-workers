disable_mlock = true

worker {
  name = "docker-worker-${name_suffix}"
  description = "A worker for a docker demo"
  // address = "worker"
  address = "worker${name_suffix}"
  controllers = ["boundary"]
}

// worker {
//   name = "docker-worker2"
//   description = "A worker for a docker demo"
//   address = "boundary"
// }

listener "tcp" {
  // address = "worker"
	address = "${name_suffix}:9202"
	purpose = "proxy"
	tls_disable = true
}

kms "aead" {
  purpose = "worker-auth"
  aead_type = "aes-gcm"
  key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
  key_id = "global_worker-auth"
}