{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    zig
    nasm
    limine
    mtools
    qemu
    OVMF
  ];

  shellHook = ''
    export LIMINE=${pkgs.limine}/share/limine
    export OVMF_CODE=${pkgs.OVMF.fd}/FV/OVMF_CODE.fd
    export OVMF_VARS=$(pwd)/OVMF_VARS.fd

    if [ ! -f OVMF_VARS.fd ]; then
      cp ${pkgs.OVMF.fd}/FV/OVMF_VARS.fd OVMF_VARS.fd
      chmod 644 OVMF_VARS.fd
    fi
  '';
}
