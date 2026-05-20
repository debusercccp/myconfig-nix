{ pkgs, ... }:
{
  home.packages = with pkgs; [
    pre-commit
  ];

  home.file.".config/pre-commit/config.yaml" = {
    text = ''
      default_stages: [commit]
      fail_fast: false

      repos:
        - repo: https://github.com/psf/black
          rev: 24.1.1
          hooks:
            - id: black

        - repo: https://github.com/pre-commit/pre-commit-hooks
          rev: v4.5.0
          hooks:
            - id: trailing-whitespace
            - id: end-of-file-fixer
            - id: check-yaml
            - id: check-json
    '';
  };

  home.file.".local/bin/init-precommit" = {
    executable = true;
    text = ''
      #!/bin/bash
      pre-commit install
      pre-commit run --all-files
    '';
  };
}
