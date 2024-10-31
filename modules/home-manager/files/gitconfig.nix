{ user }:
''
  [user]
  name = andrea11
  email = 10788630+andrea11@users.noreply.github.com
  signingkey = ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAyKRwHBMjjaxAMSHCzIz1XL1czMLPseOa7/Pif+Og3H

  [commit]
      gpgsign = true

  [core]
      sshCommand = "ssh -F ~/.ssh/config"

  [gpg]
      format = ssh

  [gpg "ssh"]
      allowedSignersFile = /Users/${user}/.ssh/allowed_signers
      program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign

  [url "git@github.com:$1/"]
  insteadOf = https://github.com/(.*)/
''
