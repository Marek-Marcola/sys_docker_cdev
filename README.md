docker cdev
===========

Docker image development tools.

Build environments: docker, podman

Install
-------
Install:

    ./cdev.sh --install
    -- or --
    cp -fv cdev.env /usr/local/etc
    cp -fv cdev.sh /usr/local/bin

Verify:

    cdev.sh --version

Help:

    cdev.sh --help

Alias:

    # cat > /etc/profile.d/zlocal-cdev.sh <<\EOF
    c() {
      local desc="@@container development (via cdev.sh)@@"
      cdev.sh $@
    }
    EOF
