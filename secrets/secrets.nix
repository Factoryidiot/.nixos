let
  #+----- User -----------------------------------
  factory = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJCkeOcvLsmdbtI/gkuqGSB5XQYLaLdF74M3Ck2vPuQ";

  #+----- Device ---------------------------------
  whio = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKtXE792p3Vt7LGUOUmSsXwga73dGH3XoktIIqLAHInA";
  tahi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFTfwNC4TVbIAaytdW7yFsmPcYMLPzcqy3QbwCSqg/48";
  rua = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7LkPduc8wbN5qbwOfVSzULZLV/SZTLH74YKRvV6Uyf";

  allKeys = [ factory whio tahi rua ];
in
{
  "github.age".publicKeys = allKeys;
  "git-config.age".publicKeys = allKeys;
}
