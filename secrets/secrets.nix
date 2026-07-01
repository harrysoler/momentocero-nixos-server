let
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAmpmjpGJq+yBOfJGdBF2Ejnd/Wao3qBmi07gUXCjBMZ harry@thinkpad";
  # optional
  # remote = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHvnxbauX4wIYR1OFm0uVh2z9HT3ShfuSgXHPvP5VKi8 root@momentocero";
in
{
  "hf-token.age".publicKeys = [ key ];
  "db-password.age".publicKeys = [ key ];
}
