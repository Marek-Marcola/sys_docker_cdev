docker cdev
===========

Container development tools.

Build environments: docker, podman

Install
-------
Install:

    ./cdev.sh --inst -x
    -- or --
    ./cdev.sh --anpb -x
    -- or --
    cp -fv cdev.env /usr/local/etc
    cp -fv cdev.sh /usr/local/bin

Postinstall:

    # cat > /etc/profile.d/zlocal-cdev.sh <<\EOF
    c() {
      local desc="@@container development (via cdev.sh)@@"
      cdev.sh $@
    }
    EOF

Verify:

    cdev.sh --ver

Help:

    cdev.sh --help
